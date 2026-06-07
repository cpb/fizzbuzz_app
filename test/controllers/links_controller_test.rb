require "test_helper"

class LinksControllerTest < ActionDispatch::IntegrationTest
  test "POST /links/publish enqueues PublishGistJob" do
    link = links(:one)
    assert_enqueued_with(job: PublishGistJob, args: [ { link_id: link.id, session_id: "" } ]) do
      post links_publish_url(id: link.id)
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
end
