require "application_system_test_case"

class WorkbookWizardTest < ApplicationSystemTestCase
  test "intro page renders and Get Started button leads to SUDS step" do
    visit new_workbook_session_path

    assert_selector "#workbook-wizard"
    assert_selector "h1", text: /Code Review Anxiety/
    assert_selector "button", text: "Get Started"

    click_button "Get Started"

    assert_selector "h2", text: /CREATE AWARENESS/
  end
end
