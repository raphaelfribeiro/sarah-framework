"""Shared fixtures for the tracker tests (R9, R12, D4).

Nothing here touches the real Trello. The stub is a local HTTP server on the
loopback interface, and every credential in this file is an obviously fake
canary: a value that, if it ever shows up in output, can only have come from
the environment the test set up.
"""

import importlib.util
import json
import socket
import sys
import unittest
import tempfile
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from unittest import mock
from urllib.parse import parse_qs, urlparse

ROOT = Path(__file__).resolve().parents[1]
SCRIPTS = ROOT / "scripts"

KEY = "KEYCANARY0123456789abcdef"
TOKEN = "TOKCANARY0123456789abcdef"
ENV = {"TRELLO_API_KEY": KEY, "TRELLO_TOKEN": TOKEN}
BOARD = "fakeboard1"


def load_script(name):
    """Import scripts/<name>.py once, under its own name."""
    if name in sys.modules:
        return sys.modules[name]
    path = SCRIPTS / f"{name}.py"
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    try:
        spec.loader.exec_module(module)
    except BaseException:
        del sys.modules[name]  # a half-loaded module must not look like a real one
        raise
    return module


class RemoteNetworkAttempt(BaseException):
    """Not an Exception on purpose: no `except Exception` in the code under test can swallow it."""


def forbid_remote_network():
    """Make any socket to a non-loopback address fail loudly for the rest of the module.

    Call from setUpModule. The suite must never reach the real Trello, and a
    patch that silently misses its target would otherwise do exactly that.
    """
    loopback = {"127.0.0.1", "::1", "localhost"}
    real_connect, real_getaddrinfo = socket.socket.connect, socket.getaddrinfo

    def connect(self, address, *args):
        if not (isinstance(address, tuple) and address[0] in loopback):
            raise RemoteNetworkAttempt("a test tried to open a non-loopback connection")
        return real_connect(self, address, *args)

    def getaddrinfo(host, *args, **kwargs):
        if host not in loopback and host is not None:
            raise RemoteNetworkAttempt("a test tried to resolve a non-loopback name")
        return real_getaddrinfo(host, *args, **kwargs)

    for patcher in (mock.patch.object(socket.socket, "connect", connect), mock.patch.object(socket, "getaddrinfo", getaddrinfo)):
        patcher.start()
        unittest.addModuleCleanup(patcher.stop)


STATE = """# S.A.R.A.H. state

## In flight

| Task | File | Phase | Level | Waiting on | Since |
| --- | --- | --- | --- | --- | --- |
{rows}
"""


def make_project(tasks=None, habits="tracker: trello\nboard: " + BOARD + "\n"):
    """A temporary project. tasks: list of (slug, title, phase, waiting, card)."""
    tmp = tempfile.TemporaryDirectory()
    root = Path(tmp.name)
    (root / "sarah" / "state").mkdir(parents=True)
    rows = []
    for slug, title, phase, waiting, card in tasks or []:
        rows.append(f"| {title} | `sarah/state/{slug}.md` | {phase} | 2 | {waiting} | 2026-01-01 |")
        body = f"# {title}\n\n**Branch:** `feature/{slug}` · **Phase:** {phase}\n"
        if card is not None:
            body += f"\nCard: {card}\n"
        (root / "sarah" / "state" / f"{slug}.md").write_text(body, encoding="utf-8")
    (root / "sarah" / "state.md").write_text(STATE.format(rows="\n".join(rows)), encoding="utf-8")
    if habits is not None:
        (root / "sarah" / "habits.md").write_text(habits, encoding="utf-8")
    return tmp, root


class StubTrello:
    """A tiny Trello on 127.0.0.1. Records every request it receives."""

    def __init__(self):
        self.requests = []
        self.permission = "private"
        self.lists = [
            {"id": "L1", "name": "Ready"},
            {"id": "L2", "name": "Doing"},
            {"id": "L3", "name": "Blocked"},
            {"id": "L4", "name": "Done"},
        ]
        self.cards = []
        self.next_id = 1
        self.override = None  # callable(handler) -> True when it answered
        self.drop_after_create = False
        self.release = threading.Event()
        stub = self

        class Handler(BaseHTTPRequestHandler):
            def log_message(self, *a):
                pass

            def _serve(self):
                url = urlparse(self.path)
                query = {k: v[0] for k, v in parse_qs(url.query).items()}
                length = int(self.headers.get("Content-Length") or 0)
                if length:
                    query.update({k: v[0] for k, v in parse_qs(self.rfile.read(length).decode()).items()})
                stub.requests.append((self.command, url.path, query))
                if stub.override and stub.override(self):
                    return
                if query.get("key") != KEY or query.get("token") != TOKEN:
                    return self._send(401, "invalid token")
                parts = url.path.strip("/").split("/")
                if parts[:2] == ["1", "boards"] and len(parts) == 3:
                    return self._send(200, {"id": parts[2], "name": "Fake Board", "prefs": {"permissionLevel": stub.permission}})
                if parts[:2] == ["1", "boards"] and parts[3:] == ["lists"]:
                    return self._send(200, stub.lists)
                if parts[:2] == ["1", "boards"] and parts[3:] == ["cards"]:  # open cards only, as Trello does
                    return self._send(200, [c for c in stub.cards if not c["closed"]])
                if parts[:2] == ["1", "boards"] and parts[3:] == ["cards", "all"]:  # the documented form for archived ones too
                    return self._send(200, stub.cards)
                if self.command == "POST" and parts == ["1", "cards"]:
                    card = {
                        "id": f"card{stub.next_id}",
                        "name": query.get("name", ""),
                        "desc": query.get("desc", ""),
                        "idList": query.get("idList", ""),
                        "closed": False,
                    }
                    stub.next_id += 1
                    stub.cards.append(card)
                    if stub.drop_after_create:
                        self.close_connection = True
                        return
                    return self._send(200, card)
                if self.command == "PUT" and parts[:2] == ["1", "cards"] and len(parts) == 3:
                    for card in stub.cards:
                        if card["id"] == parts[2]:
                            for field in ("name", "desc", "idList"):
                                if field in query:
                                    card[field] = query[field]
                            if "closed" in query:
                                card["closed"] = query["closed"] == "true"
                            return self._send(200, card)
                    return self._send(404, "card not found")
                return self._send(404, "not found")

            do_GET = do_POST = do_PUT = _serve

            def _send(self, status, body):
                raw = (json.dumps(body) if not isinstance(body, str) else body).encode()
                self.send_response(status)
                self.send_header("Content-Type", "application/json")
                self.send_header("Content-Length", str(len(raw)))
                self.end_headers()
                self.wfile.write(raw)

        self.server = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
        self.server.daemon_threads = True
        self.url = f"http://127.0.0.1:{self.server.server_address[1]}"
        self.thread = threading.Thread(target=lambda: self.server.serve_forever(poll_interval=0.02), daemon=True)

    def __enter__(self):
        self.thread.start()
        return self

    def __exit__(self, *exc):
        self.release.set()
        self.server.shutdown()
        self.server.server_close()

    def add_card(self, name, list_id="L1", desc="", closed=False):
        card = {"id": f"card{self.next_id}", "name": name, "desc": desc, "idList": list_id, "closed": closed}
        self.next_id += 1
        self.cards.append(card)
        return card

    def hang(self, handler):
        self.release.wait(5)
        return True
