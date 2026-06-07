require "test_helper"

class LlmFizzBuzzerTest < ActiveSupport::TestCase
  test "returns Fizz for multiples of 3" do
    skip "pending inference — see #51"
    assert_equal "Fizz", LlmFizzBuzzer.call(3)
    assert_equal "Fizz", LlmFizzBuzzer.call(6)
  end

  test "returns Buzz for multiples of 5" do
    skip "pending inference — see #51"
    assert_equal "Buzz", LlmFizzBuzzer.call(5)
    assert_equal "Buzz", LlmFizzBuzzer.call(10)
  end

  test "returns FizzBuzz for multiples of 15" do
    skip "pending inference — see #51"
    assert_equal "FizzBuzz", LlmFizzBuzzer.call(15)
    assert_equal "FizzBuzz", LlmFizzBuzzer.call(30)
  end
end
