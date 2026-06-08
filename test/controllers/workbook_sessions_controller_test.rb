require "test_helper"

class WorkbookSessionsControllerTest < ActionDispatch::IntegrationTest
  test "GET new returns 200 and renders the intro step of the wizard" do
    get new_workbook_session_url
    assert_response :success
    assert_select "[data-step='intro']", minimum: 1
  end
end
