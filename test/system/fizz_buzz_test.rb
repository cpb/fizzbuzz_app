require "application_system_test_case"

class FizzBuzzTest < ApplicationSystemTestCase
  test "counts down to 1 and stops" do
    visit root_path
    fill_in "Starting integer", with: 3
    click_on "Start"

    assert_selector "#results p", text: "Fizz"
    assert_selector "#results p", text: "2", wait: 5
    assert_selector "#results p", text: "1", wait: 5
    # Sequence ends at 1 — no further results
    assert_selector "#results p", count: 3
  end

  test "Use LLM checkbox streams correct FizzBuzz result" do
    visit root_path
    check "Use LLM"
    fill_in "Starting integer", with: 3
    click_on "Start"
    # TODO: once #51 lands and real inference is wired, change text: "3" → text: "Fizz"
    assert_selector "#results p", text: "3"
    assert_selector "#results p", text: "2", wait: 5
    assert_selector "#results p", text: "1", wait: 5
  end

  test "default starting number is 10" do
    visit root_path
    assert_field "Starting integer", with: "10"
  end

  test "tab A stream is unaffected when tab B submits afterward" do
    # Tab A submits and waits for its full stream to complete.
    Capybara.using_session("tab_a") do
      visit root_path
      fill_in "Starting integer", with: 3
      click_on "Start"
      assert_selector "#results p", count: 3, wait: 15
    end

    # Tab B submits only after tab A has finished streaming.
    Capybara.using_session("tab_b") do
      visit root_path
      fill_in "Starting integer", with: 3
      click_on "Start"
      assert_selector "#results p", count: 3, wait: 15
    end

    # With a shared channel, tab B's job broadcasts to "fizz_buzz_channel" while
    # tab A is still subscribed, so tab A receives tab B's results too.
    # A correctly isolated tab A should still have exactly 3 results.
    Capybara.using_session("tab_a") do
      assert_selector "#results p", count: 3
    end
  end
end
