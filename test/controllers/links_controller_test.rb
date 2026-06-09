require "test_helper"

class LinksControllerTest < ActionDispatch::IntegrationTest
  test "POST /links/publish enqueues PublishGistJob without a link_id" do
    assert_enqueued_with(job: PublishGistJob, args: []) do
      post links_publish_url
    end
    assert_response :no_content
  end

  test "GET /links shows a single Publish button and no QR code when no gist published" do
    get links_url
    assert_response :success
    # There is exactly one Publish button (page-level), not per-link
    assert_select "form[action*='publish']", count: 1
    # No QR code when no gist exists
    assert_select "[data-qr-code]", count: 0
  end

  test "authoring actions are forbidden in production" do
    original_env = Rails.env
    begin
      Rails.env = ActiveSupport::EnvironmentInquirer.new("production")
      get new_link_url
      assert_response :forbidden
      post links_url, params: { link: { title: "T", url: "https://example.com" } }
      assert_response :forbidden
      post links_publish_url
      assert_response :forbidden
    ensure
      Rails.env = original_env
    end
  end
end
