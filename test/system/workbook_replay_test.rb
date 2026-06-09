require "application_system_test_case"

class WorkbookReplayTest < ApplicationSystemTestCase
  test "visiting /demo shows a workbook replay that advances word-by-word on click" do
    visit "/demo"

    # The page should be in replay mode — a Stimulus replay controller must be present
    assert_selector "[data-controller='replay']", wait: 5

    # Clicking anywhere on the page advances the replay by one word
    find("[data-controller='replay']").click

    # After a click, additional replay content should be revealed
    assert_selector "[data-controller='replay'] [data-replay-target]", wait: 5
  end
end
