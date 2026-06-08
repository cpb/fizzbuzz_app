require "application_system_test_case"

class LinksTest < ApplicationSystemTestCase
  test "visiting the index" do
    visit links_path
    assert_selector "h1", text: "Links"
  end

  test "creating a link" do
    visit new_link_path
    fill_in "Title", with: "Test Link"
    fill_in "Url", with: "https://test.com"
    click_on "Create Link"

    assert_text "Link was successfully created."
    assert_selector "li", text: "Test Link"
  end
end
