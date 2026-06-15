require "test_helper"
require "support/eval_test_setup"

class TddIter4EvalTest < ApplicationTestCase
  include EvalTestSetup
  eval_fixtures Rails.root.join("packs/fizzbuzz_tdd/evals")
  fixtures :"prompts", :"samples"

  # Iteration 4 is the complete implementation — all 15 pass.

  test "1 is 1" do run_eval(:tdd_iter4_1) end
  test "2 is 2" do run_eval(:tdd_iter4_2) end
  test "3 is Fizz" do run_eval(:tdd_iter4_3) end
  test "4 is 4" do run_eval(:tdd_iter4_4) end
  test "5 is Buzz" do run_eval(:tdd_iter4_5) end
  test "6 is Fizz" do run_eval(:tdd_iter4_6) end
  test "7 is 7" do run_eval(:tdd_iter4_7) end
  test "8 is 8" do run_eval(:tdd_iter4_8) end
  test "9 is Fizz" do run_eval(:tdd_iter4_9) end
  test "10 is Buzz" do run_eval(:tdd_iter4_10) end
  test "11 is 11" do run_eval(:tdd_iter4_11) end
  test "12 is Fizz" do run_eval(:tdd_iter4_12) end
  test "13 is 13" do run_eval(:tdd_iter4_13) end
  test "14 is 14" do run_eval(:tdd_iter4_14) end
  test "15 is FizzBuzz" do run_eval(:tdd_iter4_15) end

  private

  def run_eval(sample_key)
    prompt = prompts(:tdd_iter4)
    sample = samples(sample_key)
    run = RubyLLM::Evals::Run.create!(prompt: prompt, active_job_id: "test-#{SecureRandom.hex(4)}", started_at: Time.current)
    RubyLLM::Evals::ExecuteSampleJob.perform_now(run_id: run.id, sample_id: sample.id)
    execution = run.prompt_executions.find_by!(sample: sample)
    assert execution.passed, "#{sample_key} should pass (got: #{execution.message.inspect})"
  end
end
