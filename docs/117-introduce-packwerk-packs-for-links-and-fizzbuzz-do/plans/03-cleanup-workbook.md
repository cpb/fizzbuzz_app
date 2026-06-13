# Plan: Delete Workbook Stubs

**Decision:** Remove the workbook controller stubs, views, and JS controllers left over
from the workbook extraction (#118). The workbook was moved to a standalone Rails app;
these files have no active routes, no application behavior, and no tests.

**Rationale:** Leaving stub files at root inflates the "infrastructure" footprint of the
root package and creates confusion about what the root package owns. Deleting them now
reduces root to only what genuinely belongs there: routes, layouts, shared assets, and
the surveys domain (until Plan 02 moves surveys into its pack).

---

## Steps

### 1. Verify no active routes

```sh
bin/rails routes | grep -iE 'replay|workbook'
```

Expected: no output (routes were cleaned up in #118). If output appears, remove those
route entries from `config/routes.rb` before proceeding.

### 2. Delete stub controllers

```sh
git rm app/controllers/replays_controller.rb
git rm app/controllers/workbook_session_replays_controller.rb
git rm -r app/controllers/workbook_sessions/
```

### 3. Delete stub views

```sh
git rm -r app/views/replays/
git rm -r app/views/workbook_sessions/
```

### 4. Delete stub JS controllers

```sh
git rm app/javascript/controllers/replay_controller.js
git rm app/javascript/controllers/word_by_word_controller.js
```

### 5. Run tests

```sh
bin/rails test
```

All tests must pass. If any test references a deleted controller or view, update or
remove that test.

### 6. Commit

```sh
git commit -m "chore: delete workbook stub controllers, views, and JS extracted in #118"
```

---

## Open Questions

None. The workbook routes were confirmed removed in #118. The JS controllers are only
referenced by the deleted views.

## Verification

- `bin/rails routes | grep -iE 'replay|workbook'` → no output
- `bin/rails test` → all tests pass
- `git ls-files app/controllers/replays_controller.rb` → no output (file deleted)
- `git ls-files app/controllers/workbook_sessions/` → no output (directory deleted)
