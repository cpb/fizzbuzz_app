# Controller Design for Issue #93 Survey Feature

## One Controller or Two?

### Existing pattern

The codebase has two controllers:

- `FizzBuzzController` — two actions (`start`, `create`), each with a single responsibility. No `respond_to` blocks; Turbo Stream updates are pushed *out* from background jobs, not from the controller itself.
- `LinksController` — four actions (`index`, `new`, `create`, `publish`). The `publish` action responds with `head :no_content` and fires a background job; Turbo Stream updates arrive via broadcast, not from a controller response.

Neither existing controller uses `respond_to do |format|` blocks. Live updates are entirely job-driven and pushed to the client via `turbo_stream_from` subscriptions in the view.

### Recommendation: one `SurveysController`

Three actions (`show`, `create`, `results`) that all relate to the same resource (the global survey) belong together in one controller. Splitting to `SurveysController` + `SurveyResultsController` would be premature and inconsistent with the codebase's flat structure. Split only if the results dashboard grows into its own rich feature with multiple actions.

---

## Action Design

### `show` — GET /survey

Renders the anonymous survey form.

```ruby
def show
  # No auth; no instance variables needed unless the form is model-backed
  # If using a form object or model:
  # @response = SurveyResponse.new
end
```

View: `app/views/surveys/show.html.erb`

### `create` — POST /survey

Accepts the submitted answer, persists it, then responds.

```ruby
def create
  SurveyResponse.create!(answer: params[:answer])
  redirect_to results_survey_path, notice: "Response recorded."
rescue ActiveRecord::RecordInvalid
  render :show, status: :unprocessable_entity
end
```

On success: redirect to `results_survey_path` (standard Post/Redirect/Get). If the UX calls for the audience to stay on the thank-you / confirmation view rather than seeing results, redirect to `survey_path` with a flash notice instead.

No `respond_to` block is needed. The form is a standard HTML form submission; Turbo Drive handles the redirect transparently. The results page (not the create action) will push live updates via a broadcast.

### `results` — GET /survey/results

Renders the live-updating aggregates dashboard.

```ruby
def results
  @counts = SurveyResponse.group(:answer).count
end
```

View: `app/views/surveys/results.html.erb`

The view subscribes to a broadcast channel:

```erb
<%= turbo_stream_from :survey_results %>
<div id="survey_results">
  <%# render aggregate bars / counts %>
</div>
```

When a new `SurveyResponse` is saved, an `after_create_commit` callback on the model (or an Active Job) broadcasts a Turbo Stream update to `:survey_results`. The controller itself does not need to respond with a Turbo Stream — exactly the same pattern used by `LinksController` and `FizzBuzzController`.

---

## CSRF Safety for Public Forms

`ApplicationController` inherits from `ActionController::Base`, which includes `protect_from_forgery with: :exception` by default in Rails 8. This applies to all controllers.

For the survey form:

- `form_with url: survey_path, method: :post` (or `form_with model: @response`) automatically injects a hidden `authenticity_token` field.
- The layout already outputs `<%= csrf_meta_tags %>` in `application.html.erb`, which is used by Turbo's JavaScript to include the token in non-form fetch requests.
- **No `skip_before_action :verify_authenticity_token` is needed.** The form token mechanism works for anonymous (not-logged-in) users just fine; it protects against cross-site forgery, not against anonymous use.

Nothing in `ApplicationController` needs to change.

---

## Turbo Stream Format Handling

The existing controllers do *not* use `respond_to` because they do not return Turbo Stream responses directly — live updates are broadcast from jobs. The survey feature should follow the same pattern:

1. `SurveyResponse` model gets an `after_create_commit` that calls `broadcast_update_to :survey_results, target: "survey_results", partial: "surveys/results_counts"`.
2. The results view has `<%= turbo_stream_from :survey_results %>`.
3. The `create` action simply redirects; it never renders a Turbo Stream response itself.

This means `respond_to` is **not needed** in `SurveysController`, matching both existing controllers.

If in the future the `create` action needs an inline Turbo Stream response (e.g., to replace the form with a thank-you message in-place without a full redirect), add:

```ruby
def create
  @response = SurveyResponse.create(answer: params[:answer])
  respond_to do |format|
    format.turbo_stream { render turbo_stream: turbo_stream.replace("survey_form", partial: "surveys/thank_you") }
    format.html { redirect_to results_survey_path }
  end
end
```

But start simple (redirect) and add `respond_to` only when the UX requires it.

---

## Controller Test Structure

Based on `fizz_buzz_controller_test.rb` and `links_controller_test.rb`, tests use `ActionDispatch::IntegrationTest` with direct HTTP verbs:

```ruby
require "test_helper"

class SurveysControllerTest < ActionDispatch::IntegrationTest
  # show
  test "GET /survey returns success" do
    get survey_path
    assert_response :success
  end

  # create — happy path
  test "POST /survey with valid answer redirects to results" do
    assert_difference("SurveyResponse.count") do
      post survey_path, params: { answer: "option_a" }
    end
    assert_redirected_to results_survey_path
  end

  # create — invalid (if validation exists)
  test "POST /survey with blank answer re-renders form" do
    post survey_path, params: { answer: "" }
    assert_response :unprocessable_entity
  end

  # results
  test "GET /survey/results returns success" do
    get results_survey_path
    assert_response :success
  end

  # results contain expected aggregates
  test "GET /survey/results shows response counts" do
    SurveyResponse.create!(answer: "option_a")
    get results_survey_path
    assert_select "[data-answer='option_a']"  # or whatever the DOM shape is
  end
end
```

System tests (in `test/system/surveys_test.rb`) should cover:
- Visiting `/survey`, filling in an option, submitting, and being redirected to `/survey/results`.
- The results count updating live after a second response is submitted (exercising the Turbo Stream broadcast path).

---

## Summary

| Decision | Choice | Rationale |
|---|---|---|
| Number of controllers | 1 (`SurveysController`) | Matches codebase flat structure; all three actions share one resource |
| Route declaration | `resource :survey` + `get :results, on: :member` | Singular resource, correct Rails idiom, short URLs |
| CSRF | No changes | `form_with` injects token; `protect_from_forgery` works for public forms |
| Turbo Stream on `create` | No — redirect only | Matches FizzBuzz/Links pattern; broadcasts from model/job, not controller |
| `respond_to` | Not needed initially | Add only if inline Turbo Stream response is required by UX |
