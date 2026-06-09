require "test_helper"

class WorkbookSessionsControllerTest < ActionDispatch::IntegrationTest
  test "GET new returns 200 and renders the intro step of the wizard" do
    get new_workbook_session_url
    assert_response :success
    assert_select "#workbook-intro"
    assert_select "h1", text: /Code Review Anxiety/
  end

  test "POST create creates a new WorkbookSession and redirects to edit" do
    assert_difference "WorkbookSession.count", 1 do
      post workbook_sessions_url
    end
    assert_redirected_to edit_workbook_session_path(WorkbookSession.last)
    assert_equal "suds_initial", WorkbookSession.last.current_step
  end

  test "PATCH update advances step and returns turbo stream" do
    session = WorkbookSession.create!(current_step: "suds_initial")
    patch workbook_session_url(session),
      params: { workbook_session: { current_step: "suds_initial", suds_initial: 8 } },
      headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_equal "tipp", session.reload.current_step
  end

  test "PATCH update with suds_initial <= 2 jumps to dear_give" do
    session = WorkbookSession.create!(current_step: "suds_initial")
    patch workbook_session_url(session),
      params: { workbook_session: { current_step: "suds_initial", suds_initial: 2 } },
      headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_equal "dear_give", session.reload.current_step
  end

  test "submitting thinking trap selection enqueues ThinkingTrapEvaluationJob and returns turbo stream with Evaluating" do
    session = WorkbookSession.create!(current_step: "select_trap")
    assert_enqueued_with(job: ThinkingTrapEvaluationJob) do
      post workbook_session_thinking_traps_url(session),
        params: { "thinking_trap[]" => "Catastrophizing" },
        headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end
    assert_match "Evaluating", response.body
  end
end
