require "test_helper"
require "support/eval_test_setup"

class YodaFizzbuzzEvalTest < ApplicationTestCase
  include EvalTestSetup
  fixtures :"fizzbuzz/prompts", :"fizzbuzz/samples"

  setup do
    @runs = []
    @sample_labels = {}
    @eval_dir = "fizzbuzz"
    @prompt_label = "yoda_fizzbuzz"
  end

  test "15 is FizzBuzz" do
    run_eval(:yoda_fizzbuzz_15)
  end

  test "3 is Fizz" do
    run_eval(:yoda_fizzbuzz_3)
  end

  test "1 is 1" do
    run_eval(:yoda_fizzbuzz_1)
  end

  test "2 is 2" do
    run_eval(:yoda_fizzbuzz_2)
  end

  test "4 is 4" do
    run_eval(:yoda_fizzbuzz_4)
  end

  test "5 is Buzz" do
    skip "VCR records known model failure"
    run_eval(:yoda_fizzbuzz_5)
  end

  test "6 is Fizz" do
    run_eval(:yoda_fizzbuzz_6)
  end

  test "7 is 7" do
    run_eval(:yoda_fizzbuzz_7)
  end

  test "8 is 8" do
    run_eval(:yoda_fizzbuzz_8)
  end

  test "9 is Fizz" do
    run_eval(:yoda_fizzbuzz_9)
  end

  test "10 is Buzz" do
    skip "VCR records known model failure"
    run_eval(:yoda_fizzbuzz_10)
  end

  test "11 is 11" do
    run_eval(:yoda_fizzbuzz_11)
  end

  test "12 is Fizz" do
    run_eval(:yoda_fizzbuzz_12)
  end

  test "13 is 13" do
    skip "VCR records known model failure"
    run_eval(:yoda_fizzbuzz_13)
  end

  test "14 is 14" do
    skip "VCR records known model failure"
    run_eval(:yoda_fizzbuzz_14)
  end

  private

  def run_eval(sample_key)
    prompt = fizzbuzz_prompts(:yoda_fizzbuzz)
    sample = fizzbuzz_samples(sample_key)
    @sample_labels[sample.id] = sample_key
    run = RubyLLM::Evals::Run.create!(prompt: prompt, active_job_id: "test-#{SecureRandom.hex(4)}", started_at: Time.current)
    @runs << run

    with_eval_cassette(sample_key.to_s) do
      RubyLLM::Evals::ExecuteSampleJob.perform_now(run_id: run.id, sample_id: sample.id)
    end

    execution = run.prompt_executions.find_by!(sample: sample)
    assert execution.passed, "Sample #{sample_key} should pass (got: #{execution.message.inspect})"
  end
end
