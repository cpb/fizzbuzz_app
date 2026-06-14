# app/

Domain logic lives in packs — see each pack's `CLAUDE.md` for routes, behaviour, and tests:

| Pack | Domain |
|---|---|
| `packs/fizzbuzz/CLAUDE.md` | FizzBuzz form, jobs, Turbo Stream broadcasting |
| `packs/links/CLAUDE.md` | Link management, Gist publishing, QR codes |
| `packs/surveys/CLAUDE.md` | Audience survey form and live results |

## Root-only routes

| Method | Path | Notes |
|---|---|---|
| `GET` | `/up` | `Rails::HealthController#show` — 200 when the app boots cleanly |
| `GET/POST` | `/evals` | `RubyLLM::Evals::Engine` — mounted eval runner |
