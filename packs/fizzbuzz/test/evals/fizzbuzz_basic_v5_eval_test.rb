require "test_helper"
require "support/eval_test_setup"

class FizzbuzzBasicV5EvalTest < ApplicationTestCase
  include EvalTestSetup
  eval_fixtures Rails.root.join("packs/fizzbuzz/evals")
  fixtures :"prompts", :"samples"

  setup do
    @runs = []
    @sample_labels = {}
    @eval_dir = Rails.root.join("packs/fizzbuzz/evals")
    @prompt_label = "fizzbuzz_basic_v5"
  end

  test "1 is 1" do
    run_eval(:fizzbuzz_basic_v5_1)
  end

  test "3 is Fizz" do
    run_eval(:fizzbuzz_basic_v5_3)
  end

  test "5 is Buzz" do
    skip "VCR records known model failure"
    run_eval(:fizzbuzz_basic_v5_5)
  end

  test "15 is FizzBuzz" do
    run_eval(:fizzbuzz_basic_v5_15)
  end

  test "invalid input echoes back" do
    run_eval(:fizzbuzz_basic_v5_invalid)
  end

  private

  def run_eval(sample_key)
    prompt = prompts(:fizzbuzz_basic_v5)
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
