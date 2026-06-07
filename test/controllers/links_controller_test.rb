require "test_helper"

class LinksControllerTest < ActionDispatch::IntegrationTest
  test "POST /links/publish enqueues PublishGistJob" do
    assert_enqueued_with(job: PublishGistJob) do
      post links_publish_url
    end
    assert_response :redirect
  end
end
