require "test_helper"
require "evals/eval_test_case"

class FizzbuzzBasicEvalTest < EvalTestCase
  fixtures :"fizzbuzz/prompts", :"fizzbuzz/samples"

  setup do
    @runs = []
    @sample_labels = {}
    @eval_dir = "fizzbuzz"
  end

  teardown do
    EvalFixtureWriter.append(@eval_dir, @runs, sample_labels: @sample_labels, prompt_label: "fizzbuzz_basic")
  end

  test "15 is FizzBuzz" do
    skip "VCR records known model failure"
    run_eval(:fizzbuzz_basic_15)
  end

  test "3 is Fizz" do
    run_eval(:fizzbuzz_basic_3)
  end

  test "5 is Buzz" do
    skip "VCR records known model failure"
    run_eval(:fizzbuzz_basic_5)
  end

  test "1 is 1" do
    skip "VCR records known model failure"
    run_eval(:fizzbuzz_basic_1)
  end

  test "2 is 2" do
    skip "VCR records known model failure"
    run_eval(:fizzbuzz_basic_2)
  end

  test "4 is 4" do
    skip "VCR records known model failure"
    run_eval(:fizzbuzz_basic_4)
  end

  test "6 is Fizz" do
    run_eval(:fizzbuzz_basic_6)
  end

  test "7 is 7" do
    skip "VCR records known model failure"
    run_eval(:fizzbuzz_basic_7)
  end

  test "8 is 8" do
    skip "VCR records known model failure"
    run_eval(:fizzbuzz_basic_8)
  end

  test "9 is Fizz" do
    run_eval(:fizzbuzz_basic_9)
  end

  test "10 is Buzz" do
    skip "VCR records known model failure"
    run_eval(:fizzbuzz_basic_10)
  end

  test "11 is 11" do
    run_eval(:fizzbuzz_basic_11)
  end

  test "12 is Fizz" do
    run_eval(:fizzbuzz_basic_12)
  end

  test "13 is 13" do
    skip "VCR records known model failure"
    run_eval(:fizzbuzz_basic_13)
  end

  test "14 is 14" do
    skip "VCR records known model failure"
    run_eval(:fizzbuzz_basic_14)
  end

  test "invalid input echoes back" do
    skip "VCR records known model failure"
    run_eval(:fizzbuzz_basic_invalid)
  end

  private

  def run_eval(sample_key)
    prompt = fizzbuzz_prompts(:fizzbuzz_basic)
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
