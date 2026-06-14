require "test_helper"

class QrCodeGeneratorTest < ApplicationTestCase
  test "returns a non-empty SVG string for a URL" do
    result = QrCodeGenerator.call("https://gist.github.com/abc")
    assert_not_nil result
    assert result.length > 0, "Expected a non-empty SVG string"
    assert_includes result, "<svg", "Expected SVG output"
  end
end
