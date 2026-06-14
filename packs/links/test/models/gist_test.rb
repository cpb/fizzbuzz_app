require "test_helper"

ActiveRecord::Schema.define do
  create_table :gists, force: true do |t|
    t.string :url
    t.datetime :published_at
    t.timestamps
  end
end

class GistTest < ApplicationTestCase
  test "gists table has url and published_at columns" do
    assert_includes Gist.column_names, "url",
      "expected gists table to have a 'url' column"
    assert_includes Gist.column_names, "published_at",
      "expected gists table to have a 'published_at' column"
  end

  test "is invalid without a url" do
    gist = Gist.new
    assert_not gist.valid?
  end

  test "latest returns the most recently published gist" do
    older = Gist.create!(url: "https://gist.github.com/older", published_at: 2.days.ago)
    newer = Gist.create!(url: "https://gist.github.com/newer", published_at: 1.day.ago)
    assert_equal newer, Gist.latest
  end
end
