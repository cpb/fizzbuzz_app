require "test_helper"

class GistPublisherTest < ActiveSupport::TestCase
  test "create_gist returns a response with html_url" do
    VCR.use_cassette("gist_publisher_create") do
      publisher = GistPublisher.new(token: "tok")
      response = publisher.create_gist(description: "Links", content: "- foo")
      assert_not_nil response[:html_url]
    end
  end
end
