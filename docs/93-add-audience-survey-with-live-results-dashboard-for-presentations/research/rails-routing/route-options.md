# Route Options for Issue #93 Survey Feature

## Existing Route Conventions

`config/routes.rb` uses three patterns:

1. **Root pair** — a bare `root` plus a matching `post "/"` for the FizzBuzz form. Simple and readable; used when there is exactly one form for the whole site.
2. **Custom named route before a resource** — `post "/links/publish"` declared before `resources :links` so it takes precedence over `links#update`. Pattern: declare custom routes first, then the REST resource.
3. **`resources :links`** — standard REST plural resource, but only `index`, `new`, `create`, and the custom `publish` action are actually used. No `show`, `edit`, `update`, or `destroy`.

There are no namespaces, no nested resources, and no `resource` (singular) declarations yet.

---

## Option A — `resources :surveys` with Member / Nested Route

```ruby
resources :surveys, only: [:new, :create] do
  get :results, on: :collection
end
# or nested:
resources :surveys, only: [:new, :create] do
  resources :results, only: [:index]
end
```

**URLs produced:**
- `GET  /surveys/new` — form
- `POST /surveys`     — submit
- `GET  /surveys/results` — dashboard

**Assessment:**
- Uses plural resource — implies many surveys with IDs. There is only one global survey, so `/surveys/new` is semantically odd and `/surveys/results` has no ID anchor.
- `new` is the right REST action for a form, but the anonymous UX expectation is `/survey` not `/surveys/new`.
- QR code URL `/surveys/new` is fine length-wise but reads as "create a new survey" to the presenter rather than "take the survey."

---

## Option B — Standalone Named Routes

```ruby
get  "/survey",         to: "surveys#show",    as: :survey
post "/survey",         to: "surveys#create"
get  "/survey/results", to: "surveys#results", as: :survey_results
```

**URLs produced:**
- `GET  /survey`         — form
- `POST /survey`         — submit
- `GET  /survey/results` — dashboard

**Assessment:**
- Complete URL control. Short, readable, QR-friendly.
- No automatic named helpers for `create` (POST to `survey_path` works because `form_with url: survey_path, method: :post` generates the correct token).
- Requires manually listing `as:` on every route. Slightly more verbose than a resource declaration.
- Does not follow Rails REST conventions, which is a mild divergence from the `resources :links` pattern in this codebase.

---

## Option C — `resource :survey` (Singular, Recommended)

```ruby
resource :survey, only: [:show, :create] do
  get :results, on: :member
end
```

This produces:

| Helper | Method | Path |
|---|---|---|
| `survey_path` | GET | `/survey` |
| `survey_path` | POST | `/survey` |
| `results_survey_path` | GET | `/survey/results` |

**Assessment:**
- `resource` (singular) is the correct Rails idiom when there is exactly one instance of a resource for all users — a global survey fits perfectly.
- `GET /survey` maps to `#show` (render form) — semantically: "show me the survey."
- `POST /survey` maps to `#create` (submit response).
- `GET /survey/results` maps to `#results` via the member block.
- All named helpers are generated automatically; no manual `as:` needed.
- URLs are short and QR-friendly: `/survey` is as short as possible.
- Consistent with `resources :links` in that the codebase uses Rails resource declarations rather than fully manual routes.

---

## Comparison Table

| Criterion | Option A (`resources`) | Option B (standalone) | Option C (`resource`) |
|---|---|---|---|
| REST fit | Weak (plural with no IDs) | None | Strong (singular global resource) |
| URL shortness | `/surveys/new` (OK) | `/survey` | `/survey` |
| Named helpers | Auto | Manual | Auto |
| Rails convention | Yes (wrong type) | No | Yes |
| QR code suitability | Good | Best | Best |
| Codebase alignment | Matches `resources :links` form | Matches root pair form | Midpoint — resource declaration, singular |

---

## Recommendation

**Option C** — `resource :survey` with a `get :results, on: :member` extra action.

Route declaration:

```ruby
resource :survey, only: [:show, :create] do
  get :results, on: :member
end
```

Place this block in `config/routes.rb` before `resources :links` (custom routes above REST resources is the existing convention, though here it is a new resource block, not a conflict).
