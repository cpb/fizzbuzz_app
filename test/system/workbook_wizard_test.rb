require "application_system_test_case"

class WorkbookWizardTest < ApplicationSystemTestCase
  test "first question is anchored at the bottom with float-up layout" do
    visit new_workbook_session_path

    # The question stack uses column-reverse layout (same as #results)
    assert_selector "#question-stack"

    # The first question/step has the .result class that triggers float-up animation
    assert_selector "#question-stack .result"
  end
end
