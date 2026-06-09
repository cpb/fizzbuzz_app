require "test_helper"
require "evals/eval_test_case"

class FizzbuzzBasicV11FullEvalTest < EvalTestCase
  fixtures :"fizzbuzz/prompts", :"fizzbuzz/samples"

  setup do
    @runs = []
    @sample_labels = {}
    @eval_dir = "fizzbuzz"
  end

  teardown do
    EvalFixtureWriter.append(@eval_dir, @runs, sample_labels: @sample_labels, prompt_label: "fizzbuzz_basic_v11")
  end

  test "1 is 1" do
    run_eval(:fizzbuzz_basic_v11_full_1)
  end

  test "2 is 2" do
    run_eval(:fizzbuzz_basic_v11_full_2)
  end

  test "3 is Fizz" do
    run_eval(:fizzbuzz_basic_v11_full_3)
  end

  test "4 is 4" do
    run_eval(:fizzbuzz_basic_v11_full_4)
  end

  test "5 is Buzz" do
    run_eval(:fizzbuzz_basic_v11_full_5)
  end

  test "6 is Fizz" do
    run_eval(:fizzbuzz_basic_v11_full_6)
  end

  test "7 is 7" do
    run_eval(:fizzbuzz_basic_v11_full_7)
  end

  test "8 is 8" do
    run_eval(:fizzbuzz_basic_v11_full_8)
  end

  test "9 is Fizz" do
    run_eval(:fizzbuzz_basic_v11_full_9)
  end

  test "10 is Buzz" do
    run_eval(:fizzbuzz_basic_v11_full_10)
  end

  test "11 is 11" do
    run_eval(:fizzbuzz_basic_v11_full_11)
  end

  test "12 is Fizz" do
    run_eval(:fizzbuzz_basic_v11_full_12)
  end

  test "13 is 13" do
    run_eval(:fizzbuzz_basic_v11_full_13)
  end

  test "14 is 14" do
    run_eval(:fizzbuzz_basic_v11_full_14)
  end

  test "15 is FizzBuzz" do
    run_eval(:fizzbuzz_basic_v11_full_15)
  end

  test "invalid input echoes back" do
    run_eval(:fizzbuzz_basic_v11_full_invalid)
  end

  private

  def run_eval(sample_key)
    prompt = fizzbuzz_prompts(:fizzbuzz_basic_v11)
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
