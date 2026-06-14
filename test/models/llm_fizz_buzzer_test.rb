require "test_helper"

class LLMFizzBuzzerTest < ApplicationTestCase
  test "returns Fizz for multiples of 3" do
    skip "pending inference — see #51"
    assert_equal "Fizz", LLMFizzBuzzer.call(3)
    assert_equal "Fizz", LLMFizzBuzzer.call(6)
  end

  test "returns Buzz for multiples of 5" do
    skip "pending inference — see #51"
    assert_equal "Buzz", LLMFizzBuzzer.call(5)
    assert_equal "Buzz", LLMFizzBuzzer.call(10)
  end

  test "returns FizzBuzz for multiples of 15" do
    skip "pending inference — see #51"
    assert_equal "FizzBuzz", LLMFizzBuzzer.call(15)
    assert_equal "FizzBuzz", LLMFizzBuzzer.call(30)
  end
end
