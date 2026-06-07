require "application_system_test_case"

class FizzBuzzTest < ApplicationSystemTestCase
  test "counts down to 1 and stops" do
    visit start_fizz_buzz_path
    fill_in "Starting integer", with: 3
    click_on "Start"

    assert_selector "#results p", text: "Fizz"
    assert_selector "#results p", text: "2", wait: 5
    assert_selector "#results p", text: "1", wait: 5
    # Sequence ends at 1 — no further results
    assert_selector "#results p", count: 3
  end

  test "default starting number is 100" do
    visit start_fizz_buzz_path
    assert_field "Starting integer", with: "100"
  end
end
