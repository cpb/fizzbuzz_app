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

  test "clicking Publish causes #qr_code to appear inline without page refresh" do
    stub_request(:post, "https://api.github.com/gists")
      .to_return(
        status: 200,
        body: { id: "test123", html_url: "https://gist.github.com/test123" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    visit links_path

    assert_no_selector "#qr_code"

    click_on "Publish"

    assert_selector "#qr_code", wait: 5
  end
end
