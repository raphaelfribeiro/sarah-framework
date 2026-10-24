#!/usr/bin/env python3
"""Install, inspect and remove S.A.R.A.H. habits in a user's project.

A habit is a pinned payload under skills/sarah-init/habits/<name>/. This script
copies it into the project, stamps each file with the plugin version and a
sha256, records it in the manifest section of sarah/habits.md, and registers its
hooks in the project's .claude/settings.json. It does this instead of the model
because merging JSON into a settings file the user already owns, and removing
exactly what was installed, are the two jobs a model gets wrong silently.

Standard library only, by design.

Usage:
    habits.py [--project DIR] [--plugin-root DIR] plan   [--remove] [--resolve PATH=ACTION] [HABIT ...]
    habits.py [--project DIR] [--plugin-root DIR] apply  [--resolve PATH=ACTION] [HABIT ...]
    habits.py [--project DIR] [--plugin-root DIR] remove [HABIT ...]
    habits.py [--project DIR] [--plugin-root DIR] status

`plan` writes nothing and lists, one action per line, exactly what `apply` (or
`remove`, with --remove) would do. `apply` and `remove` act on the habits named
and leave every other habit alone. Naming no habit changes nothing.

Conflicts are never resolved silently. A stamped file the user edited, or an
unstamped file already at a target path, is reported and left as it is until the
user chooses, with --resolve PATH=ACTION where ACTION is overwrite or keep (an
edited file) or adopt, wrap or skip (an unstamped one).

Exit codes:
    0  done, nothing pending
    1  refused or failed; nothing was written by this run's plan
    3  done, but at least one file needs a decision or was left alone

Payload layout:
    habits/<name>/habit.json   {"description", "requires", "settings"}
    habits/<name>/files/...    mirrors the project tree; every file starts with
                               no stamp, the script adds one as a `#` comment
                               line, so payload files must tolerate one
"""

from __future__ import annotations

import argparse
import copy
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path, PurePosixPath

NAME = re.compile(r"[a-z0-9_][a-z0-9_-]{0,39}")
SHA = re.compile(r"[0-9a-f]{64}")
STAMP = re.compile(rb"# sarah-habit: ([a-z0-9_][a-z0-9_-]*) (\S+) sha256:([0-9a-f]{64})\n")

# The only places an install, or a manifest row, may name. A manifest is a
# committed file, so it is input: a row outside these prefixes is refused even
# when it points inside the project (sarah/state.md must never be deletable by a
# row). Later habits that install elsewhere extend this tuple in the same commit.
PREFIXES = ("sarah/hooks/", ".github/workflows/sarah-")

SETTINGS = ".claude/settings.json"
HABITS_MD = "sarah/habits.md"
GITIGNORE = ".gitignore"
IGNORE_LINE = "sarah/.local/"
REQUIRES = ("git", "gh", "remote")
SECTIONS = ("Chosen", "Settings", "Conversation defaults", "Tracker", "Autonomy", "Manifest", "Exceptions")
TMP_PREFIX = ".sarah-tmp-"

RESOLUTIONS = {"edited": ("overwrite", "keep"), "unmanaged": ("adopt", "wrap", "skip")}


class Refused(Exception):
    """Something the engine will not do. Always reported, never swallowed."""


# --- stamps and hashes -------------------------------------------------------


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def stamp_line(habit: str, version: str, sha: str) -> str:
    return f"# sarah-habit: {habit} {version} sha256:{sha}"


def stamped(habit: str, version: str, body: bytes) -> bytes:
    """The payload with its stamp. The hash covers the body, never the stamp."""
    return stamp_line(habit, version, digest(body)).encode() + b"\n" + body


def split_stamp(data: bytes):
    m = STAMP.match(data)
    if not m:
        return None, data
    stamp = {"habit": m.group(1).decode(), "version": m.group(2).decode(), "sha256": m.group(3).decode()}
    return stamp, data[m.end():]


def content_digest(data: bytes) -> str:
    """What the manifest records: the body hash, stamp excluded."""
    return digest(split_stamp(data)[1])


def classify(data, payload_digest: str, manifest_digest) -> str:
    """absent, match, stale, edited or unmanaged for what is on disk now."""
    if data is None:
        return "absent"
    stamp, body = split_stamp(data)
    if stamp is not None:
        if digest(body) != stamp["sha256"]:
            return "edited"
        return "match" if stamp["sha256"] == payload_digest else "stale"
    if manifest_digest is not None:
        return "match" if digest(data) == manifest_digest else "edited"
    return "unmanaged"


# --- names and containment ---------------------------------------------------


def check_habit_name(name: str) -> None:
    if not isinstance(name, str) or not NAME.fullmatch(name):
        raise Refused(f"not a habit name: {name!r}")


def check_prefix(rel: str) -> None:
    if not rel.startswith(PREFIXES) or any(p in ("", ".", "..") for p in rel.split("/")):
        raise Refused(f"{rel} is outside the places a habit may install")


def contain(root, rel) -> Path:
    """The path rel names under root, or Refused.

    No absolute paths, no `..`, and no symlink anywhere along the way: the fully
    resolved path must equal the plain join. A link inside the project that
    points elsewhere in the project is refused too; the cost is a rare false
    refusal, the gain is that no check here depends on where a link leads.
    """
    if not isinstance(rel, str) or not rel or "\0" in rel or "\\" in rel or rel.startswith("/"):
        raise Refused(f"{rel!r} is not a project-relative path")
    parts = rel.split("/")
    if any(p in ("", ".", "..") for p in parts):
        raise Refused(f"{rel} is not a plain project-relative path")
    base = Path(os.path.realpath(root))
    target = base.joinpath(*parts)
    if Path(os.path.realpath(target)) != target:
        raise Refused(f"{rel} resolves outside the project or through a symlink")
    return target


def wrap_name(rel: str) -> str:
    p = PurePosixPath(rel)
    return str(p.with_name(f"{p.stem}.sarah{p.suffix}")) if p.suffix else f"{rel}.sarah"


# --- atomic writes -----------------------------------------------------------


def atomic_write(path: Path, data: bytes, mode: int) -> None:
    """Temp file in the same directory, then rename: whole or absent, never partial."""
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp = tempfile.mkstemp(dir=path.parent, prefix=TMP_PREFIX)
    try:
        with os.fdopen(fd, "wb") as f:
            f.write(data)
            f.flush()
            os.fsync(f.fileno())
        os.chmod(tmp, mode)
        os.replace(tmp, path)
    except BaseException:
        try:
            os.unlink(tmp)
        except FileNotFoundError:
            pass
        raise


def read_file(path: Path):
    try:
        return path.read_bytes()
    except FileNotFoundError:
        return None


# --- the manifest ------------------------------------------------------------


def render_manifest(rows) -> str:
    lines = ["| habit | path | sha256 |", "| --- | --- | --- |"]
    lines += [f"| {h} | {p} | {s} |" for h, p, s in rows]
    return "\n".join(lines)


def parse_manifest(lines):
    """(rows, warnings). A malformed row is ignored with one line saying so."""
    rows, warnings = [], []
    for n, line in enumerate(lines, 1):
        line = line.strip()
        if not line.startswith("|"):
            continue
        cells = [c.strip() for c in line.strip("|").split("|")]
        if cells == ["habit", "path", "sha256"] or all(re.fullmatch(r"-+", c) for c in cells):
            continue
        if len(cells) == 3 and NAME.fullmatch(cells[0]) and cells[1] and SHA.fullmatch(cells[2]):
            rows.append((cells[0], cells[1], cells[2]))
        else:
            warnings.append(f"ignored malformed manifest row {n}")
    return rows, warnings


# --- sarah/habits.md ---------------------------------------------------------

DEFAULT_BODY = {
    "Chosen": [],
    "Settings": [],
    # Read by the session-start hook: lines of the form `- <name>: off`.
    "Conversation defaults": ["<!-- One line per default you turned off, as `- <name>: off`. -->"],
    # Written by the tracker: `Last audit: YYYY-MM-DD`.
    "Tracker": ["<!-- Written by the tracker integration. -->"],
    "Autonomy": ["<!-- What the agent may do unattended. Written by /sarah-init from your answers. -->"],
    "Manifest": [],
    "Exceptions": [
        "<!-- Only you create a row, at most 14 days. -->",
        "| rule | reason | expires | granted by | date |",
        "| --- | --- | --- | --- | --- |",
    ],
}


class HabitsFile:
    """sarah/habits.md as sections. The engine owns Chosen, Manifest and the
    gitignore line of Settings; every other line is the user's and is kept."""

    def __init__(self, text=None):
        self.warnings = []
        self.preamble = ["# Habits", "", "<!-- Managed by scripts/habits.py. Edit Autonomy and Exceptions by hand; the rest is rewritten. -->"]
        self.sections = []
        if text is not None:
            self._parse(text)

    def _parse(self, text):
        self.preamble, self.sections = [], []
        current = None
        for line in text.splitlines():
            if line.startswith("## "):
                current = [line[3:].strip(), []]
                self.sections.append(current)
            elif current is None:
                self.preamble.append(line)
            else:
                current[1].append(line)
        for s in self.sections:
            s[1] = trim(s[1])
        self.preamble = trim(self.preamble)

    def body(self, title):
        for t, lines in self.sections:
            if t == title:
                return lines
        return None

    def set_body(self, title, lines):
        for s in self.sections:
            if s[0] == title:
                s[1] = trim(lines)
                return
        self.sections.append([title, trim(lines)])

    def ensure_sections(self):
        for title in SECTIONS:
            if self.body(title) is None:
                self.sections.append([title, list(DEFAULT_BODY[title])])

    @property
    def chosen(self):
        out = []
        for line in self.body("Chosen") or []:
            m = re.fullmatch(r"- ([a-z0-9_][a-z0-9_-]*)", line.strip())
            if m and m.group(1) not in out:
                out.append(m.group(1))
        return out

    @property
    def rows(self):
        rows, warnings = parse_manifest(self.body("Manifest") or [])
        self.warnings = warnings
        return rows

    @property
    def gitignore(self):
        for line in self.body("Settings") or []:
            m = re.fullmatch(r"- gitignore: (created|added|existing)", line.strip())
            if m:
                return m.group(1)
        return None

    def set_gitignore(self, value):
        keep = [l for l in (self.body("Settings") or []) if not re.fullmatch(r"- gitignore: \w+", l.strip())]
        self.set_body("Settings", keep + ([f"- gitignore: {value}"] if value else []))

    def state(self):
        return (self.chosen, self.rows, self.gitignore)

    def render(self) -> str:
        out = list(self.preamble) + [""]
        for title, lines in self.sections:
            out += [f"## {title}", ""] + lines + [""]
        return "\n".join(out).rstrip("\n") + "\n"


def trim(lines):
    lines = list(lines)
    while lines and not lines[0].strip():
        lines.pop(0)
    while lines and not lines[-1].strip():
        lines.pop()
    return lines


def load_habits_md(root: Path):
    path = contain(root, HABITS_MD)
    data = read_file(path)
    if data is None:
        return HabitsFile(), False
    return HabitsFile(data.decode("utf-8", errors="replace")), True


def compose_habits_md(habits: HabitsFile, chosen, rows, gitignore) -> HabitsFile:
    habits.ensure_sections()
    habits.set_body("Chosen", [f"- {c}" for c in chosen])
    habits.set_body("Manifest", render_manifest(rows).splitlines())
    habits.set_gitignore(gitignore)
    return habits


# --- settings.json -----------------------------------------------------------


def read_settings(path: Path):
    """(object, had_bom, existed). Invalid content is Refused, never replaced."""
    data = read_file(path)
    if data is None:
        return {}, False, False
    bom = data.startswith(b"\xef\xbb\xbf")
    try:
        text = data.decode("utf-8-sig")
        obj = json.loads(text) if text.strip() else {}
    except (UnicodeDecodeError, ValueError) as e:
        raise Refused(f"{SETTINGS} is not valid JSON ({e}); fix it by hand, nothing was changed")
    if not isinstance(obj, dict):
        raise Refused(f"{SETTINGS} is not a JSON object; fix it by hand, nothing was changed")
    return obj, bom, True


def dump_settings(obj, bom) -> bytes:
    text = json.dumps(obj, indent=2, ensure_ascii=False) + "\n"
    return (b"\xef\xbb\xbf" if bom else b"") + text.encode("utf-8")


def _hook_groups(obj, event, create):
    hooks = obj.get("hooks")
    if hooks is None:
        if not create:
            return None
        hooks = obj["hooks"] = {}
    if not isinstance(hooks, dict):
        raise Refused(f"{SETTINGS}: `hooks` is not an object; fix it by hand")
    groups = hooks.get(event)
    if groups is None:
        if not create:
            return None
        groups = hooks[event] = []
    if not isinstance(groups, list):
        raise Refused(f"{SETTINGS}: hooks.{event} is not a list; fix it by hand")
    return groups


def _commands(groups):
    for g in groups:
        if isinstance(g, dict) and isinstance(g.get("hooks"), list):
            for h in g["hooks"]:
                if isinstance(h, dict):
                    yield h.get("command")


def merge_settings(obj, entries):
    """Add each (event, matcher, command) that is not already present. Nothing
    the user wrote is moved, reordered or rewritten."""
    for event, matcher, command in entries:
        groups = _hook_groups(obj, event, create=True)
        if command in set(_commands(groups)):
            continue
        group = {"matcher": matcher} if matcher else {}
        group["hooks"] = [{"type": "command", "command": command}]
        groups.append(group)
    return obj


def remove_settings(obj, habit):
    """Drop every hook whose command points into sarah/hooks/<habit>/."""
    marker = f"sarah/hooks/{habit}/"
    removed = 0
    hooks = obj.get("hooks")
    if not isinstance(hooks, dict):
        return obj, 0
    for event in list(hooks):
        groups = hooks[event]
        if not isinstance(groups, list):
            continue
        kept_groups = []
        for g in groups:
            if isinstance(g, dict) and isinstance(g.get("hooks"), list):
                keep = [h for h in g["hooks"] if not (isinstance(h, dict) and marker in str(h.get("command", "")))]
                gone = len(g["hooks"]) - len(keep)
                removed += gone
                if gone and not keep:
                    continue
                if gone:
                    g = dict(g, hooks=keep)
            kept_groups.append(g)
        if len(kept_groups) != len(groups):
            if kept_groups:
                hooks[event] = kept_groups
            else:
                del hooks[event]
        elif kept_groups != groups:
            hooks[event] = kept_groups
    if removed and not hooks:
        del obj["hooks"]
    return obj, removed


def command_for(rel: str) -> str:
    # Absolute through the environment, never relative: a hook run from a
    # subdirectory would otherwise fail open with exit 127.
    return f'sh "$CLAUDE_PROJECT_DIR/{rel}"'


# --- payloads ----------------------------------------------------------------


class Payload:
    def __init__(self, name, files, settings, requires):
        self.name, self.files, self.settings, self.requires = name, files, settings, requires


def plugin_version(plugin: Path) -> str:
    try:
        version = json.loads((plugin / ".claude-plugin" / "plugin.json").read_text())["version"]
    except (OSError, ValueError, KeyError, TypeError) as e:
        raise Refused(f"cannot read the plugin version from {plugin}/.claude-plugin/plugin.json ({e})")
    if not isinstance(version, str) or not re.fullmatch(r"\S+", version):
        raise Refused("the plugin version is not a plain string")
    return version


def load_payload(plugin: Path, name: str) -> Payload:
    check_habit_name(name)
    base = plugin / "skills" / "sarah-init" / "habits" / name
    if base.is_symlink() or not base.is_dir():
        raise Refused(f"no such habit: {name}")
    try:
        meta = json.loads((base / "habit.json").read_text())
    except (OSError, ValueError) as e:
        raise Refused(f"habit {name}: cannot read habit.json ({e})")
    requires = meta.get("requires", [])
    if not isinstance(requires, list) or any(r not in REQUIRES for r in requires):
        raise Refused(f"habit {name}: `requires` may only list {', '.join(REQUIRES)}")
    files = {}
    root = base / "files"
    for dirpath, dirnames, filenames in os.walk(root, followlinks=False):
        for entry in dirnames + filenames:
            if (Path(dirpath) / entry).is_symlink():
                raise Refused(f"habit {name}: payload contains a symlink ({entry})")
        for fn in filenames:
            full = Path(dirpath) / fn
            rel = full.relative_to(root).as_posix()
            check_prefix(rel)
            if "|" in rel or "\n" in rel:
                raise Refused(f"habit {name}: {rel} cannot be listed in a manifest")
            files[rel] = (full.read_bytes(), 0o755 if full.stat().st_mode & 0o111 else 0o644)
    settings = []
    for s in meta.get("settings", []):
        if not (isinstance(s, dict) and isinstance(s.get("event"), str) and isinstance(s.get("file"), str)):
            raise Refused(f"habit {name}: a settings entry needs `event` and `file`")
        if s["file"] not in files:
            raise Refused(f"habit {name}: settings entry names {s['file']}, which the payload does not ship")
        settings.append((s["event"], s.get("matcher") or "", s["file"]))
    return Payload(name, files, settings, requires)


def unmet(root: Path, requirement: str) -> bool:
    if requirement == "git":
        return not (root / ".git").exists()
    if requirement == "gh":
        return shutil.which("gh") is None
    try:
        out = subprocess.run(["git", "-C", str(root), "remote"], capture_output=True, text=True, timeout=10)
    except (OSError, subprocess.SubprocessError):
        return True
    return out.returncode != 0 or not out.stdout.strip()


# --- the plan ----------------------------------------------------------------


class Plan:
    def __init__(self):
        self.lines = []        # human-readable, one action per line
        self.errors = []
        self.writes = []       # (rel, bytes, mode) for payload files
        self.settings = []     # (event, matcher, command) to add
        self.chosen = []
        self.rows = []
        self.gitignore = None  # value to record
        self.ignore_action = None
        self.pending = False   # a conflict is waiting for the user
        self.warnings = []


def parse_resolutions(items):
    out = {}
    for item in items or []:
        path, sep, action = item.partition("=")
        if not sep or action not in {a for acts in RESOLUTIONS.values() for a in acts}:
            raise Refused(f"--resolve wants PATH=ACTION with ACTION one of overwrite, keep, adopt, wrap, skip: {item!r}")
        out[path] = action
    return out


def build_apply_plan(root: Path, plugin: Path, names, resolutions) -> Plan:
    plan = Plan()
    version = plugin_version(plugin)
    habits_md, _ = load_habits_md(root)
    old_state = habits_md.state()
    plan.warnings += habits_md.warnings
    chosen, rows = list(old_state[0]), list(old_state[1])
    payloads = [load_payload(plugin, n) for n in dict.fromkeys(names)]

    for p in payloads:
        for req in p.requires:
            if unmet(root, req):
                plan.errors.append(f"habit {p.name} needs {req}, which this project does not have; nothing installed")
    unknown = set(resolutions) - {rel for p in payloads for rel in p.files}
    for rel in sorted(unknown):
        plan.errors.append(f"--resolve names {rel}, which no habit being applied installs")
    if plan.errors:
        return plan

    # Rows already in the manifest are input. A row outside the project or the
    # install prefixes is dropped and reported; it is never acted on.
    live = []
    for habit, rel, sha in rows:
        if habit in {p.name for p in payloads}:
            try:
                contain(root, rel)
                check_prefix(rel)
            except Refused as e:
                plan.lines.append(f"refused {rel} {e}")
                plan.pending = True
                continue
        live.append((habit, rel, sha))
    rows = live
    owner = {rel: (habit, sha) for habit, rel, sha in rows}

    new_rows_for = {}
    wanted_settings = []
    for p in payloads:
        mine = {rel: sha for habit, rel, sha in rows if habit == p.name}
        out_rows = {}
        final_target = {}
        for rel in sorted(p.files):
            body, mode = p.files[rel]
            pd = digest(body)
            target, forced = rel, resolutions.get(rel)
            alt = wrap_name(rel)
            if rel not in mine and alt in mine:
                target = alt
            for candidate in (target,):
                if candidate in owner and owner[candidate][0] != p.name:
                    plan.errors.append(f"{candidate} is already listed for habit {owner[candidate][0]}")
            try:
                for _ in range(2):
                    path = contain(root, target)
                    check_prefix(target)
                    data = read_file(path)
                    if data is not None and not path.is_file():
                        raise Refused(f"{target} is not a regular file")
                    cls = classify(data, pd, mine.get(target))
                    if cls == "unmanaged" and forced == "wrap" and target == rel:
                        plan.lines.append(f"wrap {rel} -> {alt}")
                        target = alt
                        continue
                    break
            except Refused as e:
                plan.errors.append(str(e))
                continue

            if cls == "absent":
                plan.lines.append(f"create {target}")
                plan.writes.append((target, stamped(p.name, version, body), mode, p.name))
                out_rows[target] = pd
            elif cls == "stale":
                plan.lines.append(f"update {target}")
                plan.writes.append((target, stamped(p.name, version, body), mode, p.name))
                out_rows[target] = pd
            elif cls == "match":
                plan.lines.append(f"unchanged {target}")
                out_rows[target] = mine.get(target) or content_digest(data)
            elif cls == "edited":
                if forced == "overwrite":
                    plan.lines.append(f"update {target}")
                    plan.writes.append((target, stamped(p.name, version, body), mode, p.name))
                    out_rows[target] = pd
                else:
                    plan.lines.append(f"conflict {target} edited (you changed it; --resolve {rel}=overwrite or keep)")
                    plan.pending = True
                    if target in mine:
                        out_rows[target] = mine[target]
            else:  # unmanaged
                if forced == "adopt":
                    plan.lines.append(f"adopt {target}")
                    out_rows[target] = digest(data)
                elif forced == "skip":
                    plan.lines.append(f"skip {target} (yours, left alone)")
                    plan.pending = True
                else:
                    plan.lines.append(f"conflict {target} unmanaged (a file of yours is here; --resolve {rel}=adopt, wrap or skip)")
                    plan.pending = True
            if forced and forced not in RESOLUTIONS.get(cls, ()) and cls not in ("absent", "match", "stale"):
                plan.errors.append(f"--resolve {rel}={forced} does not apply to a {cls} file")
            if forced and cls in ("absent", "match", "stale") and not (forced == "wrap" and target != rel):
                plan.errors.append(f"--resolve {rel}={forced}: there is no conflict at that path")
            if target in out_rows:
                final_target[rel] = target
        new_rows_for[p.name] = out_rows
        for event, matcher, rel in p.settings:
            if rel in final_target:
                wanted_settings.append((event, matcher, command_for(final_target[rel])))

    # Carry forward rows this run does not decide: other habits, and files an
    # older version of this habit installed that this version no longer ships.
    names_applied = {p.name for p in payloads}
    final_rows = [(h, r, s) for h, r, s in rows if h not in names_applied]
    for p in payloads:
        shipped = set(new_rows_for[p.name])
        final_rows += [(h, r, s) for h, r, s in rows if h == p.name and r not in shipped and r not in {x for x in p.files}
                       and wrap_name(r) not in shipped and not any(wrap_name(f) == r for f in p.files)]
        final_rows += [(p.name, r, s) for r, s in sorted(new_rows_for[p.name].items())]
    plan.rows = final_rows
    plan.chosen = chosen + [p.name for p in payloads if p.name not in chosen]

    if wanted_settings:
        obj, bom, existed = read_settings(contain(root, SETTINGS))
        before = copy.deepcopy(obj)
        merged = merge_settings(copy.deepcopy(obj), wanted_settings)
        if merged != before:
            have = set()
            for event, _, command in wanted_settings:
                groups = _hook_groups(before, event, create=False) or []
                if command in set(_commands(groups)):
                    have.add((event, command))
            for event, matcher, command in wanted_settings:
                if (event, command) not in have:
                    plan.lines.append(f"settings add {event} {matcher or '*'} {command}")
                    plan.settings.append((event, matcher, command))
            plan.settings_obj = (merged, bom)
    plan.gitignore = habits_md.gitignore
    if plan.chosen:
        path = contain(root, GITIGNORE)
        data = read_file(path)
        lines = data.decode("utf-8", errors="replace").splitlines() if data is not None else []
        if IGNORE_LINE not in [l.strip() for l in lines] and (IGNORE_LINE.rstrip("/") not in [l.strip() for l in lines]):
            plan.ignore_action = "append"
            plan.lines.append(f"gitignore add {IGNORE_LINE}")
            if plan.gitignore is None:
                plan.gitignore = "added" if data is not None else "created"
        elif plan.gitignore is None:
            plan.gitignore = "existing"

    new_state = (plan.chosen, plan.rows, plan.gitignore)
    plan.habits_md = (habits_md, new_state != old_state or not (root / HABITS_MD).exists() and bool(plan.chosen))
    if plan.habits_md[1]:
        plan.lines.append("habits.md update")
    return plan


def execute_apply(root: Path, plan: Plan) -> None:
    """Intent first (the manifest), then files, settings, .gitignore. A crash at
    any point leaves rows `status` reports as missing and a re-run completes."""
    habits_md, dirty = plan.habits_md
    if dirty:
        compose_habits_md(habits_md, plan.chosen, plan.rows, plan.gitignore)
        atomic_write(contain(root, HABITS_MD), habits_md.render().encode("utf-8"), 0o644)
    for rel, data, mode, _ in plan.writes:
        atomic_write(contain(root, rel), data, mode)
    if plan.settings:
        merged, bom = plan.settings_obj
        atomic_write(contain(root, SETTINGS), dump_settings(merged, bom), 0o644)
    if plan.ignore_action == "append":
        path = contain(root, GITIGNORE)
        data = read_file(path)
        text = data.decode("utf-8", errors="replace") if data is not None else ""
        if text and not text.endswith("\n"):
            text += "\n"
        atomic_write(path, (text + IGNORE_LINE + "\n").encode("utf-8"), 0o644 if data is None else (path.stat().st_mode & 0o777))


# --- remove ------------------------------------------------------------------


def prune_dirs(root: Path, path: Path) -> None:
    base = Path(os.path.realpath(root))
    parent = path.parent
    while parent != base and base in parent.parents:
        try:
            parent.rmdir()
        except OSError:
            return
        parent = parent.parent


def do_remove(root: Path, names, dry: bool):
    """(lines, pending). Deletes only manifest files whose hash still matches."""
    lines, pending = [], False
    habits_md, exists = load_habits_md(root)
    chosen, rows, gitignore = habits_md.state()
    verb = (lambda done, would: would if dry else done)
    removed_any_setting = False
    settings_obj = bom = None
    targets = list(dict.fromkeys(names))
    for n in targets:
        check_habit_name(n)
    remaining = [r for r in rows if r[0] not in targets]

    sp = contain(root, SETTINGS)
    raw = read_file(sp)
    needs_settings = raw is not None and any(f"sarah/hooks/{n}/".encode() in raw for n in targets)
    if needs_settings:
        settings_obj, bom, _ = read_settings(sp)   # Refused here aborts before anything is touched
        for n in targets:
            settings_obj, count = remove_settings(settings_obj, n)
            if count:
                removed_any_setting = True
                lines.append(f"settings {verb('removed', 'remove')} {n} ({count} entr{'y' if count == 1 else 'ies'})")

    for habit, rel, sha in rows:
        if habit not in targets:
            continue
        try:
            path = contain(root, rel)
            check_prefix(rel)
        except Refused as e:
            lines.append(f"refused {rel} {e}")
            pending = True
            continue
        data = read_file(path)
        if data is None:
            lines.append(f"gone {rel}")
        elif not path.is_file():
            lines.append(f"kept {rel} not a regular file")
            pending = True
        elif content_digest(data) == sha or digest(data) == sha:
            lines.append(f"{verb('removed', 'remove')} {rel}")
            if not dry:
                path.unlink()
                prune_dirs(root, path)
        else:
            lines.append(f"kept {rel} edited (yours now; no longer managed)")
            pending = True

    if not dry:
        if removed_any_setting:
            if settings_obj == {}:
                sp.unlink()
                prune_dirs(root, sp)
            else:
                atomic_write(sp, dump_settings(settings_obj, bom), 0o644)
        left = [c for c in chosen if c not in targets]
        if not left and gitignore in ("created", "added"):
            gp = contain(root, GITIGNORE)
            data = read_file(gp)
            if data is not None:
                kept = [l for l in data.decode("utf-8", errors="replace").splitlines() if l.strip() != IGNORE_LINE]
                if kept:
                    atomic_write(gp, ("\n".join(kept) + "\n").encode("utf-8"), gp.stat().st_mode & 0o777)
                else:
                    gp.unlink()
            gitignore = None
        if exists:
            compose_habits_md(habits_md, left, remaining, gitignore)
            atomic_write(contain(root, HABITS_MD), habits_md.render().encode("utf-8"), 0o644)
    elif any(n in chosen for n in targets):
        lines.append("habits.md update")
    for n in targets:
        if n not in chosen and not any(r[0] == n for r in rows):
            lines.append(f"not-installed {n}")
    return lines, pending


# --- status ------------------------------------------------------------------


def do_status(root: Path, plugin: Path):
    habits_md, exists = load_habits_md(root)
    chosen, rows, gitignore = habits_md.state()
    lines = list(habits_md.warnings)
    problems = bool(habits_md.warnings)
    lines.append("chosen: " + (", ".join(chosen) if chosen else "none"))
    for habit, rel, sha in rows:
        if habit not in chosen:
            lines.append(f"orphan {rel} (listed for {habit}, which is not chosen)")
            problems = True
        try:
            path = contain(root, rel)
            check_prefix(rel)
        except Refused as e:
            lines.append(f"refused {rel} {e}")
            problems = True
            continue
        data = read_file(path)
        if data is None:
            lines.append(f"missing {rel} (an apply was interrupted or the file was deleted; run apply again)")
            problems = True
        elif content_digest(data) != sha and digest(data) != sha:
            lines.append(f"edited {rel}")
            problems = True
        else:
            lines.append(f"ok {rel}")
    raw = read_file(contain(root, SETTINGS)) or b""
    for habit in chosen:
        try:
            wants = bool(load_payload(plugin, habit).settings)
        except Refused:
            continue
        if wants and f"sarah/hooks/{habit}/".encode() not in raw:
            lines.append(f"missing settings entry for {habit} (run apply again)")
            problems = True
    if chosen:
        data = read_file(contain(root, GITIGNORE)) or b""
        if IGNORE_LINE not in [l.strip() for l in data.decode("utf-8", errors="replace").splitlines()]:
            lines.append(f"missing {GITIGNORE} entry {IGNORE_LINE} (run apply again)")
            problems = True
    return lines, problems


# --- command line ------------------------------------------------------------


def build_parser():
    ap = argparse.ArgumentParser(prog="habits.py", description="Install, inspect and remove S.A.R.A.H. habits.")
    ap.add_argument("--project", default=".", help="the project root (default: current directory)")
    ap.add_argument("--plugin-root", default=str(Path(__file__).resolve().parents[1]), help="the plugin root holding the payloads")
    sub = ap.add_subparsers(dest="command", required=True)
    for name in ("plan", "apply", "remove"):
        sp = sub.add_parser(name)
        sp.add_argument("habits", nargs="*")
        if name != "remove":
            sp.add_argument("--resolve", action="append", default=[], metavar="PATH=ACTION")
        if name == "plan":
            sp.add_argument("--remove", action="store_true", help="plan a removal instead of an install")
    sub.add_parser("status")
    return ap


def emit(lines):
    for line in lines:
        print(line)


def main(argv=None) -> int:
    args = build_parser().parse_args(argv)
    try:
        root = Path(args.project)
        if not root.is_dir():
            raise Refused(f"{args.project} is not a directory")
        root = Path(os.path.realpath(root))
        plugin = Path(args.plugin_root)

        if args.command == "status":
            lines, problems = do_status(root, plugin)
            emit(lines)
            return 1 if problems else 0

        if args.command == "remove" or (args.command == "plan" and args.remove):
            lines, pending = do_remove(root, args.habits, dry=args.command == "plan")
            emit(lines or ["nothing to do"])
            return 3 if pending and args.command == "remove" else 0

        plan = build_apply_plan(root, plugin, args.habits, parse_resolutions(args.resolve))
        emit(plan.warnings)
        if plan.errors:
            emit(f"error: {e}" for e in plan.errors)
            return 1
        emit(plan.lines or ["nothing to do"])
        if args.command == "apply":
            execute_apply(root, plan)
            return 3 if plan.pending else 0
        return 0
    except Refused as e:
        print(f"error: {e}")
        return 1
    except OSError as e:
        print(f"error: {e}; the project is left in a state `status` can explain, run apply again")
        return 1


if __name__ == "__main__":
    sys.exit(main())
