# packs/links

## Source

| File | Role |
|---|---|
| `app/controllers/links_controller.rb` | CRUD + publish action; authoring forbidden in production |
| `app/models/link.rb` | Link record (title, url) |
| `app/models/gist.rb` | Tracks published Gist (url, published_at) |
| `app/models/gist_publisher.rb` | GitHub Gist API client |
| `app/jobs/publish_gist_job.rb` | Creates/updates a Gist from all links; writes `Gist` record |
| `app/views/links/` | Index, new-link form, link partial, QR code partial |
| `lib/tasks/db_fixtures.rake` | `db:fixtures:export` — exports links and gists tables to YAML |

## Routes

| Method | Path | Action | UI surface |
|---|---|---|---|
| `GET` | `/links` | `LinksController#index` | List of links with Publish button |
| `GET` | `/links/new` | `LinksController#new` | New link form |
| `POST` | `/links` | `LinksController#create` | Create link, redirect to index |
| `DELETE` | `/links/:id` | `LinksController#destroy` | Remove link |
| `POST` | `/links/publish` | `LinksController#publish` | Enqueue `PublishGistJob`; forbidden in production |

Authoring actions (`new`, `create`, `destroy`, `publish`) return 403 when `Rails.env.production?`.

## Tests

| Test file | What it covers |
|---|---|
| `test/controllers/links_controller_test.rb` | Publish enqueues job; index renders single Publish button; authoring forbidden in production |
| `test/models/link_test.rb` | Valid with title + url; invalid without either |
| `test/models/gist_test.rb` | Schema columns present; invalid without url; `Gist.latest` returns most recently published |
| `test/models/gist_publisher_test.rb` | `create_gist` / `update_gist` via VCR; markdown bullet formatting; gist filename |
| `test/models/qr_code_generator_test.rb` | `QrCodeGenerator` (root model) smoke tests live here |
| `test/jobs/publish_gist_job_test.rb` | Calls `create_gist` then `update_gist`; creates `Gist` record |
| `test/system/links_test.rb` | Visit index; create link; Publish → QR code appears inline without page refresh |

VCR cassettes for `gist_publisher_test.rb` live in `test/cassettes/`.
