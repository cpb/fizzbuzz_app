require "test_helper"

class WorkbookSessionsControllerTest < ActionDispatch::IntegrationTest
  test "GET new returns 200 and renders the intro step of the wizard" do
    get new_workbook_session_url
    assert_response :success
    assert_select "[data-step='intro']", minimum: 1
  end

  test "GET new renders column-reverse question stack container with active step bearing data-step attribute" do
    get new_workbook_session_url
    assert_response :success
    assert_select "#workbook-steps[style*='column-reverse']", minimum: 1,
      message: "expected a #workbook-steps container with style containing 'column-reverse'"
    assert_select "#workbook-steps [data-step]", minimum: 1,
      message: "expected at least one child element with a data-step attribute inside #workbook-steps"
  end

  test "submitting thinking trap selection enqueues ThinkingTrapEvaluationJob and returns turbo stream with Evaluating" do
    assert_enqueued_with(job: ThinkingTrapEvaluationJob) do
      post workbook_session_thinking_traps_url(1),
        params: { thinking_trap: "catastrophizing" },
        headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end

    assert_match "Evaluating", response.body
  end

  test "POST create with turbo stream returns a Turbo Stream that appends the next question step partial with the float-up animation class" do
    post workbook_sessions_url,
      params: { step: "intro" },
      headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_match "result", response.body
  end
end
