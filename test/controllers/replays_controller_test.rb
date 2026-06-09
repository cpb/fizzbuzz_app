require "test_helper"

class ReplaysControllerTest < ActionDispatch::IntegrationTest
  test "GET show renders a hint indicating what to do next during replay" do
    session = WorkbookSession.create!(current_step: "suds_initial")
    get workbook_session_replay_url(session)
    assert_response :success
    assert_select "[data-testid='replay-hint']"
  end
end
