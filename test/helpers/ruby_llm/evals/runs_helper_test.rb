require "test_helper"

module RubyLLM
  module Evals
    class RunsHelperTest < ApplicationViewTestCase
      include RunsHelper

      test "fizzbuzz_expected_category for multiples of 15" do
        assert_equal :fizzbuzz, fizzbuzz_expected_category(15)
        assert_equal :fizzbuzz, fizzbuzz_expected_category(30)
        assert_equal :fizzbuzz, fizzbuzz_expected_category("45")
      end

      test "fizzbuzz_expected_category for multiples of 3 only" do
        assert_equal :fizz, fizzbuzz_expected_category(3)
        assert_equal :fizz, fizzbuzz_expected_category(6)
        assert_equal :fizz, fizzbuzz_expected_category("9")
      end

      test "fizzbuzz_expected_category for multiples of 5 only" do
        assert_equal :buzz, fizzbuzz_expected_category(5)
        assert_equal :buzz, fizzbuzz_expected_category(10)
        assert_equal :buzz, fizzbuzz_expected_category("20")
      end

      test "fizzbuzz_expected_category for plain numbers" do
        assert_equal :number, fizzbuzz_expected_category(1)
        assert_equal :number, fizzbuzz_expected_category(7)
        assert_equal :number, fizzbuzz_expected_category("13")
      end

      test "fizzbuzz_predicted_category detects fizzbuzz" do
        assert_equal :fizzbuzz, fizzbuzz_predicted_category("FizzBuzz")
        assert_equal :fizzbuzz, fizzbuzz_predicted_category("fizzbuzz")
        assert_equal :fizzbuzz, fizzbuzz_predicted_category('{"result": "FizzBuzz"}')
      end

      test "fizzbuzz_predicted_category detects fizz" do
        assert_equal :fizz, fizzbuzz_predicted_category("Fizz")
        assert_equal :fizz, fizzbuzz_predicted_category("fizz")
        assert_equal :fizz, fizzbuzz_predicted_category("The answer is Fizz.")
      end

      test "fizzbuzz_predicted_category detects buzz" do
        assert_equal :buzz, fizzbuzz_predicted_category("Buzz")
        assert_equal :buzz, fizzbuzz_predicted_category("buzz")
      end

      test "fizzbuzz_predicted_category returns number for digit-containing output" do
        assert_equal :number, fizzbuzz_predicted_category("7")
        assert_equal :number, fizzbuzz_predicted_category("13")
        assert_equal :number, fizzbuzz_predicted_category("The answer is 4.")
      end

      test "fizzbuzz_predicted_category returns other for non-numeric non-fizzbuzz output" do
        assert_equal :other, fizzbuzz_predicted_category("Neither.")
        assert_equal :other, fizzbuzz_predicted_category("I don't know")
        assert_equal :other, fizzbuzz_predicted_category("")
        assert_equal :other, fizzbuzz_predicted_category("None of the above")
      end

      test "fizzbuzz_cell_style returns dark color for passed expected cell" do
        entry = { expected: :fizz, predicted: :fizz, passed: true }
        assert_includes fizzbuzz_cell_style(:fizz, entry), "#282828"
      end

      test "fizzbuzz_cell_style returns red for failed expected cell" do
        entry = { expected: :fizz, predicted: :buzz, passed: false }
        assert_includes fizzbuzz_cell_style(:fizz, entry), "#ff3860"
      end

      test "fizzbuzz_cell_style returns blue for predicted cell when wrong" do
        entry = { expected: :fizz, predicted: :buzz, passed: false }
        assert_includes fizzbuzz_cell_style(:buzz, entry), "#b3ddf2"
      end

      test "fizzbuzz_cell_style returns gray for untested cells" do
        entry = { expected: :fizz, predicted: :fizz, passed: true }
        assert_includes fizzbuzz_cell_style(:buzz, entry), "#f0f0f0"
        assert_includes fizzbuzz_cell_style(:fizzbuzz, entry), "#f0f0f0"
        assert_includes fizzbuzz_cell_style(:number, entry), "#f0f0f0"
        assert_includes fizzbuzz_cell_style(:other, entry), "#f0f0f0"
      end

      test "fizzbuzz_cell_style marks other row blue when model output was unrecognized" do
        entry = { expected: :fizzbuzz, predicted: :other, passed: false }
        assert_includes fizzbuzz_cell_style(:other, entry), "#b3ddf2"
        assert_includes fizzbuzz_cell_style(:fizzbuzz, entry), "#ff3860"
      end
    end
  end
end
