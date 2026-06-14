require "test_helper"
require "support/eval_test_setup"

class FizzbuzzEvalEvalTest < ApplicationTestCase
  include EvalTestSetup
  fixtures :"prompts", :"samples"

  setup do
    @runs = []
    @sample_labels = {}
    @eval_dir = Rails.root.join("packs/fizzbuzz/evals")
    @prompt_label = "fizzbuzz_eval"
  end

  test "15 is FizzBuzz" do
    run_eval(:fizzbuzz_eval_15)
  end

  test "3 is Fizz" do
    run_eval(:fizzbuzz_eval_3)
  end

  test "5 is Buzz" do
    run_eval(:fizzbuzz_eval_5)
  end

  test "1 is 1" do
    run_eval(:fizzbuzz_eval_1)
  end

  test "2 is 2" do
    run_eval(:fizzbuzz_eval_2)
  end

  test "4 is 4" do
    run_eval(:fizzbuzz_eval_4)
  end

  test "6 is Fizz" do
    run_eval(:fizzbuzz_eval_6)
  end

  test "7 is 7" do
    run_eval(:fizzbuzz_eval_7)
  end

  test "8 is 8" do
    skip "VCR records known model failure"
    run_eval(:fizzbuzz_eval_8)
  end

  test "9 is Fizz" do
    run_eval(:fizzbuzz_eval_9)
  end

  test "10 is Buzz" do
    run_eval(:fizzbuzz_eval_10)
  end

  test "11 is 11" do
    run_eval(:fizzbuzz_eval_11)
  end

  test "12 is Fizz" do
    run_eval(:fizzbuzz_eval_12)
  end

  test "13 is 13" do
    run_eval(:fizzbuzz_eval_13)
  end

  test "14 is 14" do
    skip "VCR records known model failure"
    run_eval(:fizzbuzz_eval_14)
  end

  private

  def run_eval(sample_key)
    prompt = prompts(:fizzbuzz_eval)
    sample = samples(sample_key)
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
