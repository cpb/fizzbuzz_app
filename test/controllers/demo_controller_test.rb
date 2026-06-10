require "test_helper"

class DemoControllerTest < ActionDispatch::IntegrationTest
  test "GET /demo redirects to the workbook_sessions new page" do
    get "/demo"
    assert_redirected_to new_workbook_session_url
  end
end
