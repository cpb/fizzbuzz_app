require "test_helper"

class GistTest < ActiveSupport::TestCase
  test "gists table has url and published_at columns" do
    assert_includes Gist.column_names, "url",
      "expected gists table to have a 'url' column"
    assert_includes Gist.column_names, "published_at",
      "expected gists table to have a 'published_at' column"
  end
end
