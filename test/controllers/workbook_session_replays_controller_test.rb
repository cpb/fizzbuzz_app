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
    post advance_workbook_session_replay_url(@session),
      params: { replay_step: "suds_initial" },
      headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_select "[data-replay-step='tipp']"
  end

  test "GET show renders replay step with word-by-word Stimulus controller and word-target spans" do
    session = WorkbookSession.create!(
      current_step: "rational_response",
      rational_response: "This is a balanced thought response."
    )

    get workbook_session_replay_path(session)

    assert_response :success
    assert_select "[data-controller='word-by-word']" do
      assert_select "[data-word-by-word-target='word']"
    end
  end
end
