require "test_helper"

class PublishGistJobTest < ActiveJob::TestCase
  test "calls create_gist then update_gist on publisher" do
    link = links(:one)
    calls = []

    spy = Object.new
    spy.define_singleton_method(:create_gist) { |**| calls << :create_gist; { id: "abc", html_url: "https://gist.github.com/abc" } }
    spy.define_singleton_method(:update_gist) { |**| calls << :update_gist; true }

    original_new = GistPublisher.method(:new)
    GistPublisher.define_singleton_method(:new) { |**| spy }

    begin
      PublishGistJob.perform_now(link_id: link.id)
    ensure
      GistPublisher.singleton_class.define_method(:new, original_new)
    end

    assert_equal [ :create_gist, :update_gist ], calls,
      "Expected create_gist then update_gist to be called, but got: #{calls.inspect}"
  end
end
