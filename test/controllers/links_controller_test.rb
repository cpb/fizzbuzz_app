require "test_helper"

class LinksControllerTest < ActionDispatch::IntegrationTest
  test "POST /links/publish enqueues PublishGistJob without a link_id" do
    assert_enqueued_with(job: PublishGistJob, args: [ {} ]) do
      post links_publish_url
    end
    assert_response :no_content
  end
end
