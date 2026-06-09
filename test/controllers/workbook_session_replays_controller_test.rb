require "test_helper"

class WorkbookSessionReplaysControllerTest < ActionDispatch::IntegrationTest
  setup do
    @session = WorkbookSession.create!(current_step: "summary", suds_initial: 8)
  end

  test "GET show renders the first workbook step (suds_initial)" do
    get workbook_session_replay_url(@session)
    assert_response :success
    assert_select "[data-replay-step='suds_initial']"
  end

  test "POST advance responds with the next step in sequence" do
    # Start the replay at suds_initial, advance to tipp
    post advance_workbook_session_replay_url(@session),
      params: { replay_step: "suds_initial" },
      headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_select "[data-replay-step='tipp']"
  end
end
