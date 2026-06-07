require "test_helper"

class LinksControllerTest < ActionDispatch::IntegrationTest
  test "POST /links/publish enqueues PublishGistJob" do
    link = links(:one)
    assert_enqueued_with(job: PublishGistJob, args: [ { link_id: link.id, session_id: "" } ]) do
      post links_publish_url(id: link.id)
    end
    assert_response :no_content
  end
end
