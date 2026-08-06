# The brief

Identical for both arms. Given verbatim, with nothing added or removed.

It is deliberately underspecified in places. Real requests are, and how a
process handles ambiguity is part of what this study measures. Nothing in it
mentions tests, security, architecture, review, or any part of either arm's
process — naming those would tell both arms what they are being scored on.

---

I need a webhook receiver service in Python.

External services will POST JSON payloads to it. Each request carries a
signature header so we can tell the delivery really came from the sender, and a
timestamp header. There's a shared secret per sender — we have a handful of
senders, each with their own secret and their own endpoint path.

When a delivery arrives and checks out, it should be handed to a handler that
does something with the payload. For now the handler can just write the event
somewhere durable — we'll wire up real processing later, so keep that seam
clean.

Senders retry aggressively when they don't get a fast 2xx, and some of them send
the same delivery more than once even when we did respond. We can't have
duplicates causing duplicate work downstream.

It needs to be installable and have a test suite. Make it something we can
actually run.
