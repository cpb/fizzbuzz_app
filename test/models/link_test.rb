require "test_helper"

class LinkTest < ActiveSupport::TestCase
  test "valid with title and url" do
    assert Link.new(title: "GitHub", url: "https://github.com").valid?
  end

  test "invalid without title" do
    refute Link.new(url: "https://github.com").valid?
  end

  test "invalid without url" do
    refute Link.new(title: "GitHub").valid?
  end
end
