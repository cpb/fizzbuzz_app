require "test_helper"
require "evals/eval_test_case"
require "eval_loader"

class FizzbuzzBasicEvalTest < EvalTestCase
  setup do
    EvalLoader.seed_dir("fizzbuzz")
    @prompt = RubyLLM::Evals::Prompt.find_by!(slug: "fizzbuzz-basic")
    @runs = []
    @eval_dir = "fizzbuzz"
  end

  teardown do
    EvalFixtureWriter.append(@eval_dir, @runs)
  end

  test "evaluates sample 15" do
    sample = @prompt.samples.find_by!(variables: { "number" => "15" })
    run = RubyLLM::Evals::Run.create!(prompt: @prompt, active_job_id: "test-#{SecureRandom.hex(4)}", started_at: Time.current)
    @runs << run

    with_eval_cassette("fizzbuzz_basic_15") do
      RubyLLM::Evals::ExecuteSampleJob.perform_now(run_id: run.id, sample_id: sample.id)
    end

    execution = run.prompt_executions.find_by!(sample: sample)
    puts "\nDEBUG: Execution output: #{execution.output}"
    assert execution.passed, "Sample 15 should pass regex check"
  end
end
