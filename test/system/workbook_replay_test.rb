require "application_system_test_case"

class WorkbookReplayTest < ApplicationSystemTestCase
  test "visiting /demo shows a workbook replay that advances word-by-word on click" do
    visit "/demo"

    assert_selector "[data-controller='replay']", wait: 5

    find("[data-controller='replay']").click

    # "auth" is a word from the seeded auth-PR scenario; it must appear after the first click
    assert_text "auth", wait: 5
  end
end
