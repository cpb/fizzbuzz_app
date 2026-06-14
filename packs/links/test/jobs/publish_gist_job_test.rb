require "test_helper"

ActiveRecord::Schema.define do
  create_table :gists, force: true do |t|
    t.string :url
    t.datetime :published_at
    t.timestamps
  end
end

class PublishGistJobTest < ApplicationJobTestCase
  test "calls create_gist then update_gist on publisher" do
    link = links(:one)
    calls = []

    spy = Object.new
    spy.define_singleton_method(:create_gist) { |**| calls << :create_gist; { id: "abc", html_url: "https://gist.github.com/abc" } }
    spy.define_singleton_method(:update_gist) { |**| calls << :update_gist; true }

    original_new = GistPublisher.method(:new)
    GistPublisher.define_singleton_method(:new) { |**| spy }

    begin
      PublishGistJob.perform_now(link_id: link.id, session_id: "test")
    ensure
      GistPublisher.singleton_class.define_method(:new, original_new)
    end

    assert_equal [ :create_gist, :update_gist ], calls,
      "Expected create_gist then update_gist to be called, but got: #{calls.inspect}"
  end

  test "publishes all links and creates a Gist record" do
    spy = Object.new
    spy.define_singleton_method(:create_gist) { |**| { id: "abc123", html_url: "https://gist.github.com/abc123" } }
    original_new = GistPublisher.method(:new)
    GistPublisher.define_singleton_method(:new) { |**| spy }
    begin
      assert_difference "Gist.count", 1 do
        PublishGistJob.perform_now
      end
      assert_equal "https://gist.github.com/abc123", Gist.last.url
    ensure
      GistPublisher.singleton_class.define_method(:new, original_new)
    end
  end
end
