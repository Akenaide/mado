# Admin page: script runner + Meili status

## Context

Kevin wants an internal admin page for the backend, reachable only behind
nginx httpaccess (no app-level auth needed). Goal for this iteration, per
his answers:

- Backend-rendered (FastAPI), not a new Flutter section — nginx already
  gates access, and the actions are simple "click a button, see the
  result" operations, so a second frontend app would be pure overhead.
- Scope for now: **run `bin/` scripts from the browser** and **view
  Meilisearch index status**. "Hide a set" and future translations are
  explicitly deferred — not part of this plan, just flagged as future
  direction.

FastAPI has no Django-admin equivalent (`sqladmin`/`starlette-admin` are
built around SQLAlchemy models, which don't apply here — there's no SQL
DB, just Meilisearch + JSON files). Flutter has no admin scaffold either.
So: plain server-rendered HTML, no new template engine dependency — the
codebase already renders HTML by hand in `main.py`'s `og_card` route
(f-strings + `HTMLResponse`), so the admin pages reuse that same pattern
instead of adding Jinja2 for a handful of pages.

## Approach

New module `back/src/admin.py`:

- `APIRouter(prefix="/admin")`, included from `main.py` like the existing
  `graphql_app` router.
- `SCRIPTS: dict[str, Callable]` — a fixed registry mapping a script name
  to the already-existing `main()` functions in `src/bin/*.py`
  (`create_indexes`, `import_sets`, `import_cards`,
  `compute_related_cards`, `try_meili_connect`). Fixed registry (not a
  directory scan) so only known, reviewed scripts are runnable from the
  web.
- `_jobs: dict[str, dict]` — in-memory per-script state:
  `{"status": "idle"|"running"|"done"|"error", "log": str}`. No new
  storage; a restart just resets state, which is fine for this internal
  tool.
- `_run_script(name)` — runs `SCRIPTS[name]()` on a `threading.Thread`,
  catching exceptions into `status="error"` + traceback in the log. Runs
  in a thread (not `asyncio.create_task`) because the bin scripts call
  `asyncio.run()` internally and would fail on the event loop thread.
  - **Race on double-click**: the `POST /run` route sets
    `_jobs[name] = {"status": "running", "log": ""}` synchronously,
    *before* calling `thread.start()`. Since the async route handler runs
    to completion without yielding until that point, a second rapid POST
    deterministically sees `"running"` and no-ops — no lock needed.
  - **Live log output**: stdout is captured with a tiny custom writer
    (not a buffered `io.StringIO()` copied in at the end), so
    `_jobs[name]["log"]` grows as the script prints, and a manual reload
    of the log page mid-run shows partial progress:
    ```python
    class _JobWriter:
        def __init__(self, name): self.name = name
        def write(self, s): _jobs[self.name]["log"] += s
        def flush(self): pass
    ```
    used via `contextlib.redirect_stdout(_JobWriter(name))`. `str +=` on
    a dict value is a single GIL-atomic step, so this is safe with one
    writer thread and the request-handling thread only reading.
- Routes:
  - `GET /admin` — index page, just two links (`/admin/meili`,
    `/admin/scripts`), no styling, no dashboard content. Static markup,
    no branching — no dedicated test.
  - `GET /admin/meili` — table of index stats: iterate
    `client.get_indexes()["results"]`, call `.get_stats()` on each,
    render `uid`, `number_of_documents`, `is_indexing`, plus a "Delete"
    form per row (handy in active dev, when a schema/reindex needs a
    clean slate instead of `podman compose down -v`). Each delete form
    has `onsubmit="return confirm('Delete index ' + uid + '?')"` — a
    native browser confirm, no JS framework, guards the one destructive
    action on this page.
  - `POST /admin/meili/{uid}/delete` — calls `client.delete_index(uid)`;
    redirects (303) back to `/admin/meili`. No try/except for a
    not-found `uid` — let it 500 via FastAPI's default handler; this is
    rare enough (stale page, double delete) that a stack-trace response
    is fine diagnostic feedback for an internal tool.
  - `GET /admin/scripts` — table of registered scripts with current
    status, a "Run" form (`POST`) per row, and a "View log" link to
    `/admin/scripts/{name}/log` per row (always present, not just while
    running — done/error output is worth checking too).
  - `POST /admin/scripts/{name}/run` — 404 if `name` not in `SCRIPTS`; if
    not already running, marks it running (see race note above) and
    starts the background thread; redirects (303) back to
    `/admin/scripts`.
  - `GET /admin/scripts/{name}/log` — `PlainTextResponse` of the full
    captured log so far; manual reload to see progress (no
    auto-refresh/polling — considered and dropped, see Behavior 6).

`main.py` changes: import `admin` module, `app.include_router(admin.router)`.

## TDD plan

Tests live in `back/tests/test_admin.py`, using the existing `client`
fixture (`TestClient(app)`) from `back/tests/conftest.py`. Meili calls are
mocked the same way `mock_meili` does in `conftest.py`
(`patch("admin.get_meili_client", return_value=mock_client)`).

### Behavior 1 — Meili status page renders index stats

**Red**
```python
def test_meili_status_shows_index_stats(client, monkeypatch):
    """
    /admin/meili renders each index's document count and indexing state.

    Given:
    - get_meili_client().get_indexes() returns one index "sets" (uid="sets")
    - that index's get_stats() returns number_of_documents=42, is_indexing=False

    When:
    - GET /admin/meili

    Then:
    - response status is 200
    - response body contains "sets", "42", and "False" (or an idle marker)
    """
```
Mock via `admin.get_meili_client`. Expected failure: `admin` module/route
doesn't exist yet → import/404, then once route exists, assertion failure
on missing stats text (goal: get to an assertion failure, so stub the
route first if needed before writing the real body).

**Green** — implement `GET /admin/meili` as described above.

**Refactor** — extract a small `_render_table(headers, rows)` helper if
the HTML string-building starts repeating between the two list pages;
skip if it doesn't (only two pages, may not be worth it).

### Behavior 2 — Deleting an index removes it via the Meili client

**Red**
```python
def test_delete_index_calls_meili_delete(client, monkeypatch):
    """
    POST /admin/meili/{uid}/delete deletes the given index and redirects back.

    Given:
    - get_meili_client() returns a mock client

    When:
    - POST /admin/meili/sets/delete

    Then:
    - response is a redirect (303) to /admin/meili
    - mock_client.delete_index was called with "sets"
    """
```
Expected failure: route doesn't exist yet → 404, not the intended
assertion failure — write the route stub first if needed, then let the
`delete_index` assertion fail before implementing the call. Note: the
`onsubmit="confirm(...)"` guard is a browser-side HTML attribute on the
form — `TestClient` posts directly and bypasses it, same as any real
non-JS client would; nothing to unit-test there beyond checking the
attribute string is present in the rendered `/admin/meili` page from
Behavior 1 if desired (optional, low value — skip).

**Green** — implement `POST /admin/meili/{uid}/delete` calling
`get_meili_client().delete_index(uid)` then redirecting, and add the
`onsubmit` confirm attribute to the delete form rendered in
`GET /admin/meili`.

**Refactor** — none expected.

### Behavior 3 — Scripts page lists the registry, idle by default

**Red**
```python
def test_scripts_page_lists_registered_scripts(client):
    """
    /admin/scripts lists every script in the registry with idle status.

    Given:
    - no script has been run yet (fresh _jobs state)

    When:
    - GET /admin/scripts

    Then:
    - response status is 200
    - response body contains each key of admin.SCRIPTS (e.g. "import_sets")
    - response body contains "idle" for each
    """
```

**Green** — implement `GET /admin/scripts` rendering `admin.SCRIPTS` keys
+ `_jobs.get(name, {"status": "idle"})["status"]`.

**Refactor** — none expected.

### Behavior 4 — Running a script executes it and captures output

**Red**
```python
def test_run_script_executes_and_captures_stdout(client, monkeypatch):
    """
    POST /admin/scripts/{name}/run executes the registered callable and
    captures its stdout into the job log.

    Given:
    - admin.SCRIPTS is monkeypatched to {"fake": lambda: print("done")}

    When:
    - POST /admin/scripts/fake/run
    - (test waits for the background thread to finish, e.g. by joining
      the thread admin._run_script returns/stores, or by polling
      admin._jobs["fake"]["status"] briefly)

    Then:
    - response is a redirect (303) to /admin/scripts
    - admin._jobs["fake"]["status"] == "done"
    - admin._jobs["fake"]["log"] contains "done"
    """
```
To make this deterministically testable without real sleeps/polling,
`_run_script` should be written so the test can call it directly (or the
route can expose the thread object) — plan: have the route call
`_run_script(name)` which itself spawns and returns the `Thread`; test
calls `admin._run_script("fake")` directly and `.join()`s it, rather than
going through the HTTP POST, to assert on `_jobs` deterministically. A
second, simpler test hits the POST route and just asserts the redirect
status, without asserting on completed state (avoids flakiness from
timing).

A third small test covers the double-click race directly:
`test_run_script_twice_quickly_only_starts_one_thread` — call the route
twice back-to-back with a script that blocks briefly (e.g. a
`threading.Event`-gated fake), assert only one thread actually ran the
callable (e.g. via a call counter), because the route marks `"running"`
synchronously before starting the thread.

**Green** — implement `_run_script` + the `POST` route: route sets
`_jobs[name] = {"status": "running", "log": ""}` synchronously, then
starts `threading.Thread(target=_run_script, args=(name,))`;
`_run_script` uses `_JobWriter` + `redirect_stdout` so `_jobs[name]["log"]`
updates incrementally, and sets `status` to `"done"`/`"error"` at the end.

**Refactor** — none expected; keep the thread-capture logic in one small
function.

### Behavior 5 — Unknown script name returns 404

**Red**
```python
def test_run_unknown_script_returns_404(client):
    """
    POST /admin/scripts/{name}/run 404s for a name not in the registry.

    Given:
    - "does-not-exist" is not a key in admin.SCRIPTS

    When:
    - POST /admin/scripts/does-not-exist/run

    Then:
    - response status is 404
    """
```

**Green** — add the registry-membership check at the top of the route.

**Refactor** — none expected.

### Behavior 6 — Log endpoint returns captured output as text

**Red**
```python
def test_script_log_endpoint_returns_captured_text(client, monkeypatch):
    """
    GET /admin/scripts/{name}/log returns the job's captured log as plain text.

    Given:
    - admin._jobs["fake"] = {"status": "done", "log": "hello from script"}

    When:
    - GET /admin/scripts/fake/log

    Then:
    - response status is 200
    - response text == "hello from script"
    - content-type is text/plain
    """
```

**Green** — implement `GET /admin/scripts/{name}/log` returning
`PlainTextResponse(_jobs.get(name, {}).get("log", ""))`.

**Refactor** — none expected.

Note: an HTML view with `<meta http-equiv="refresh">` for auto-polling
while running was considered and explicitly dropped — it would have
required switching this endpoint to `text/html` + `html.escape()`-ing the
log, which is more moving parts than a manual-reload plain-text log
justifies for this iteration.

## Files touched

- `back/src/admin.py` (new)
- `back/src/main.py` — register the router
- `back/tests/test_admin.py` (new)

## Out of scope (flagged for later, not implemented here)

- "Hide a set" admin action — needs a decision on where the hidden flag
  persists given `import_sets.py` re-upserts all set docs from JSON each
  run (Kevin: "just an idea, don't implement it, it's for a bigger
  picture").
- Translations, per card — real future requirement, but too big to be
  part of this admin page; Kevin will scope it as its own separate
  project (candidates worth evaluating there: Weblate, Tolgee — both
  self-hosted TMS with built-in translation memory + glossary, so that
  matching logic doesn't need to be built from scratch).
- Any app-level auth (nginx httpaccess is the auth boundary).

## Verification

- `cd back && uv run pytest tests/test_admin.py -v` — all 5 (or however
  many) new tests pass; then run the full suite
  (`uv run pytest`) to confirm no regressions.
- Manual: `just dev`, visit `http://localhost/admin`, click through to
  `/admin/meili` (should show real index stats from the dev Meilisearch)
  and `/admin/scripts` (run e.g. `create_indexes`, confirm log shows
  "Indexes configured.").

## Checklist

- [ ] No production code written before a failing test points at it
- [ ] No feature flags, backwards-compat shims, or half-finished abstractions
- [ ] Imports use `from app import models` style (module, not symbol) —
      matches existing style in `back/src` (e.g. `from models import
      object_set`); admin.py will `import` bin modules similarly rather
      than importing their `main` symbols directly where practical
- [ ] No comments added unless the WHY is non-obvious (e.g. why threads
      instead of asyncio tasks)
