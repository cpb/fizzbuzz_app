require "application_system_test_case"

class WorkbookWizardTest < ApplicationSystemTestCase
  test "intro page renders and Get Started button leads to SUDS step" do
    visit new_workbook_session_path

    assert_selector "#workbook-intro"
    assert_selector "h1", text: /Code Review Anxiety/i
    assert_button "Get Started"

    click_button "Get Started"

    assert_selector "h2", text: /CREATE AWARENESS/
  end
end
