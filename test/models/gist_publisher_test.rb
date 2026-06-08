require "test_helper"

class GistPublisherTest < ActiveSupport::TestCase
  setup do
    token = Rails.application.credentials.dig(:github, :token) || "test-token"
    @publisher = GistPublisher.new(token: token)
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

  test "create_gist formats links as markdown bullet list" do
    publisher = GistPublisher.new(token: "fake-token")

    captured_body = nil
    WebMock.stub_request(:post, "https://api.github.com/gists").with do |req|
      captured_body = JSON.parse(req.body)
      true
    end.to_return(status: 200, body: { id: "abc123", html_url: "https://gist.github.com/abc123" }.to_json, headers: { "Content-Type" => "application/json" })

    publisher.create_gist(description: "Links", links: [ links(:one), links(:two) ])

    expected_content = "- [GitHub](https://github.com)\n- [Google](https://google.com)"
    assert_equal expected_content, captured_body["files"]["links.md"]["content"]
  end

  test "create_gist uses 'Necessary Eval: Links!' as the gist filename" do
    publisher = GistPublisher.new(token: "fake-token")

    captured_body = nil
    WebMock.stub_request(:post, "https://api.github.com/gists").with do |req|
      captured_body = JSON.parse(req.body)
      true
    end.to_return(status: 200, body: { id: "abc123", html_url: "https://gist.github.com/abc123" }.to_json, headers: { "Content-Type" => "application/json" })

    publisher.create_gist(description: "Links", links: [ links(:one) ])

    assert captured_body["files"].key?("Necessary Eval: Links!"),
      "Expected gist files to have key 'Necessary Eval: Links!' but got keys: #{captured_body["files"].keys.inspect}"
  end
end
