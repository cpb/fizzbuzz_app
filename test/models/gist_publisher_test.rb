require "test_helper"

class GistPublisherTest < ActiveSupport::TestCase
  setup do
    @publisher = GistPublisher.new(token: Rails.application.credentials.github.token)
  end

  test "create_gist returns a response with html_url" do
    VCR.use_cassette("gist_publisher_create") do
      response = @publisher.create_gist(description: "Links", content: "- foo")
      assert_not_nil response[:html_url]
    end
  end

  test "update_gist returns true on success" do
    VCR.use_cassette("gist_publisher_update") do
      result = @publisher.update_gist(id: "ba576e2f3aa24bdb1920b3cb1f358eba", content: "- foo\n- bar")
      assert result
    end
  end
end
