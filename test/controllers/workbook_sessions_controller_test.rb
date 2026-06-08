require "test_helper"

class WorkbookSessionsControllerTest < ActionDispatch::IntegrationTest
  test "GET new returns 200 and renders the intro step of the wizard" do
    get new_workbook_session_url
    assert_response :success
    assert_select "[data-step='intro']", minimum: 1
  end

  test "submitting thinking trap selection enqueues ThinkingTrapEvaluationJob and returns turbo stream with Evaluating" do
    assert_enqueued_with(job: ThinkingTrapEvaluationJob) do
      post workbook_session_thinking_traps_url(1),
        params: { thinking_trap: "catastrophizing" },
        headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end

    assert_match "Evaluating", response.body
  end
end
