require "test_helper"
require "support/eval_test_setup"

class TddIter2EvalTest < ApplicationTestCase
  include EvalTestSetup
  eval_fixtures Rails.root.join("packs/fizzbuzz_tdd/evals")
  fixtures :"prompts", :"samples"

  # Iteration 2 adds Buzz — 10/15 pass (numbers + Buzz; Fizz and FizzBuzz still fail).

  test "1 is 1" do run_eval(:tdd_iter2_1) end
  test "2 is 2" do run_eval(:tdd_iter2_2) end
  test "4 is 4" do run_eval(:tdd_iter2_4) end
  test "5 is Buzz" do run_eval(:tdd_iter2_5) end
  test "7 is 7" do run_eval(:tdd_iter2_7) end
  test "8 is 8" do run_eval(:tdd_iter2_8) end
  test "10 is Buzz" do run_eval(:tdd_iter2_10) end
  test "11 is 11" do run_eval(:tdd_iter2_11) end
  test "13 is 13" do run_eval(:tdd_iter2_13) end
  test "14 is 14" do run_eval(:tdd_iter2_14) end

  private

  def run_eval(sample_key)
    prompt = prompts(:tdd_iter2)
    sample = samples(sample_key)
    run = RubyLLM::Evals::Run.create!(prompt: prompt, active_job_id: "test-#{SecureRandom.hex(4)}", started_at: Time.current)
    RubyLLM::Evals::ExecuteSampleJob.perform_now(run_id: run.id, sample_id: sample.id)
    execution = run.prompt_executions.find_by!(sample: sample)
    assert execution.passed, "#{sample_key} should pass (got: #{execution.message.inspect})"
  end
end
