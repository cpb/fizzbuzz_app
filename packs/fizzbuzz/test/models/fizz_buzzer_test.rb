require "test_helper"

class FizzBuzzerTest < ApplicationTestCase
  test "returns number as string for normal numbers" do
    assert_equal "1", FizzBuzzer.call(1)
    assert_equal "2", FizzBuzzer.call(2)
  end

  test "returns Fizz for multiples of 3" do
    assert_equal "Fizz", FizzBuzzer.call(3)
    assert_equal "Fizz", FizzBuzzer.call(6)
  end

  test "returns Buzz for multiples of 5" do
    assert_equal "Buzz", FizzBuzzer.call(5)
    assert_equal "Buzz", FizzBuzzer.call(10)
  end

  test "returns FizzBuzz for multiples of 15" do
    assert_equal "FizzBuzz", FizzBuzzer.call(15)
    assert_equal "FizzBuzz", FizzBuzzer.call(30)
  end
end
