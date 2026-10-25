"""The credential never leaves the process (security gap 7, invariant 7).

Trello takes the key and token as query parameters, so the worst case is real:
urllib's own errors carry the full URL. Each test forces one error path with the
canary values in the environment, then checks every place output can go.
"""

import io
import os
import traceback
import unittest
import urllib.error
from contextlib import redirect_stderr, redirect_stdout
from unittest import mock

from tests.tracker_support import forbid_remote_network, ENV, KEY, TOKEN, load_script, make_project
from tests.unit.test_tracker_unit import FakeResponse, http_error

tracker = load_script("tracker")
trello = load_script("tracker_trello")


def setUpModule():
    forbid_remote_network()


class RedactionTests(unittest.TestCase):
    def setUp(self):
        self.tmp, self.root = make_project([("a", "Alpha", "build", "", "pending")])
        self.addCleanup(self.tmp.cleanup)

    def assertClean(self, *texts):
        for text in texts:
            self.assertNotIn(KEY, text)
            self.assertNotIn(TOKEN, text)

    def run_verb(self, verb, opened, extra=()):
        out, err = io.StringIO(), io.StringIO()
        with mock.patch.dict(os.environ, ENV, clear=True), mock.patch.object(trello.TrelloClient, "_open", opened), \
                mock.patch.object(trello.time, "sleep", lambda s: None), redirect_stdout(out), redirect_stderr(err):
            code = tracker.main([verb, "--root", str(self.root), *extra])
        self.assertClean(out.getvalue(), err.getvalue())
        return code

    def test_every_status_error_through_every_verb(self):
        for verb in ("check", "intake", "sync", "audit", "report"):
            for status in (401, 403, 404, 429, 500, 503):
                headers = {"Retry-After": "1"} if status == 429 else {}
                self.run_verb(verb, mock.Mock(side_effect=http_error(status, headers)), ["--force"])

    def test_transport_errors(self):
        errors = [
            urllib.error.URLError(f"connect failed key={KEY} token={TOKEN}"),
            ConnectionRefusedError(f"https://api.trello.com/1/x?key={KEY}&token={TOKEN}"),
            TimeoutError(f"timed out token={TOKEN}"),
            RuntimeError(f"surprise {KEY}"),
            ValueError(f"/1/boards?token={TOKEN}"),
        ]
        for exc in errors:
            for verb in ("check", "sync"):
                self.run_verb(verb, mock.Mock(side_effect=exc))

    def test_bad_bodies(self):
        for body in (b"<html>" + KEY.encode() + b"</html>", b'{"name": "' + TOKEN.encode()):
            self.run_verb("check", mock.Mock(return_value=FakeResponse(body)))

    def test_exceptions_carry_no_secret_and_no_chained_context(self):
        c = trello.TrelloClient(KEY, TOKEN, sleep=lambda s: None)
        for exc in (http_error(401), http_error(500), urllib.error.URLError(f"{KEY}{TOKEN}"), RuntimeError(KEY), TimeoutError(TOKEN)):
            with mock.patch.object(trello.TrelloClient, "_open", side_effect=exc):
                try:
                    c.request("GET", "/1/boards/x")
                except trello.TrackerError as caught:
                    rendered = "".join(traceback.format_exception(caught))
                    self.assertClean(str(caught), repr(caught), rendered, repr(caught.args))
                    self.assertIsNone(caught.__cause__)
                    self.assertTrue(caught.__suppress_context__)
                else:
                    self.fail("no error raised")

    def test_client_repr_hides_the_credentials(self):
        c = trello.TrelloClient(KEY, TOKEN)
        self.assertClean(repr(c), str(c))

    def test_unexpected_crash_prints_no_traceback_with_secrets(self):
        out, err = io.StringIO(), io.StringIO()
        boom = RuntimeError(f"internal {KEY} {TOKEN}")
        with mock.patch.dict(os.environ, ENV, clear=True), mock.patch.object(tracker, "run_verb", side_effect=boom), \
                redirect_stdout(out), redirect_stderr(err):
            code = tracker.main(["check", "--root", str(self.root)])
        self.assertEqual(code, 1)
        self.assertClean(out.getvalue(), err.getvalue())

    def test_usage_errors_do_not_echo_arguments(self):
        for argv in (["check", f"--token={TOKEN}"], ["check", KEY], [TOKEN], ["check", "--root"]):
            out, err = io.StringIO(), io.StringIO()
            with mock.patch.dict(os.environ, ENV, clear=True), redirect_stdout(out), redirect_stderr(err):
                code = tracker.main(argv)
            self.assertEqual(code, 2)
            self.assertClean(out.getvalue(), err.getvalue())

    def test_redact_function_catches_query_strings_and_encoded_forms(self):
        text = f"GET /1/x?key={KEY}&token={TOKEN} and key=other123 and %41"
        cleaned = trello.redact(text, [KEY, TOKEN])
        self.assertClean(cleaned)
        self.assertNotIn("other123", cleaned)
        self.assertClean(trello.redact("a b+c", ["a b+c"]), trello.redact("a%20b%2Bc", ["a b+c"]))


if __name__ == "__main__":
    unittest.main()
