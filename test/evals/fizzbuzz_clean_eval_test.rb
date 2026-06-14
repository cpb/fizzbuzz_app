require "test_helper"
require "support/eval_test_setup"

class FizzbuzzCleanEvalTest < ApplicationTestCase
  include EvalTestSetup
  fixtures :"fizzbuzz/prompts", :"fizzbuzz/samples"

  setup do
    @runs = []
    @sample_labels = {}
    @eval_dir = "fizzbuzz"
    @prompt_label = "fizzbuzz_clean"
  end

  test "15 is FizzBuzz" do
    run_eval(:fizzbuzz_clean_15)
  end

  test "3 is Fizz" do
    run_eval(:fizzbuzz_clean_3)
  end

  test "5 is Buzz" do
    run_eval(:fizzbuzz_clean_5)
  end

  test "1 is 1" do
    run_eval(:fizzbuzz_clean_1)
  end

  test "2 is 2" do
    skip "VCR records known model failure"
    run_eval(:fizzbuzz_clean_2)
  end

  test "4 is 4" do
    skip "VCR records known model failure"
    run_eval(:fizzbuzz_clean_4)
  end

  test "6 is Fizz" do
    skip "VCR records known model failure"
    run_eval(:fizzbuzz_clean_6)
  end

  test "7 is 7" do
    run_eval(:fizzbuzz_clean_7)
  end

  test "8 is 8" do
    skip "VCR records known model failure"
    run_eval(:fizzbuzz_clean_8)
  end

  test "9 is Fizz" do
    skip "VCR records known model failure"
    run_eval(:fizzbuzz_clean_9)
  end

  test "10 is Buzz" do
    run_eval(:fizzbuzz_clean_10)
  end

  test "11 is 11" do
    skip "VCR records known model failure"
    run_eval(:fizzbuzz_clean_11)
  end

  test "12 is Fizz" do
    skip "VCR records known model failure"
    run_eval(:fizzbuzz_clean_12)
  end

  test "13 is 13" do
    skip "VCR records known model failure"
    run_eval(:fizzbuzz_clean_13)
  end

  test "14 is 14" do
    skip "VCR records known model failure"
    run_eval(:fizzbuzz_clean_14)
  end

  private

  def run_eval(sample_key)
    prompt = fizzbuzz_prompts(:fizzbuzz_clean)
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
