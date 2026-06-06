require "application_system_test_case"

class FizzBuzzTest < ApplicationSystemTestCase
  test "visiting the start page and starting fizzbuzz" do
    visit start_fizz_buzz_path
    fill_in "Starting integer", with: 1
    click_on "Start"

    assert_selector "#results p", text: "1"
    # The next number should appear automatically
    assert_selector "#results p", text: "2", wait: 5
  end
end
