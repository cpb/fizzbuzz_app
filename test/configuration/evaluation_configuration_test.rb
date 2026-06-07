require "test_helper"

module RubyLLM
  module Evals
    class EvaluationConfigurationTest < ActiveSupport::TestCase
      # This test uses the fixtures copied from ruby_llm-evals
      fixtures :"ruby_llm/evals/prompts", :"ruby_llm/evals/samples", :"ruby_llm/evals/runs", :"ruby_llm/evals/prompt_executions"

      test "job creates prompt execution when executed" do
        VCR.use_cassette("execute_sample_job_creates_prompt_execution") do
          prompt = ruby_llm_evals_prompts(:one)
          run = RubyLLM::Evals::Run.create!(prompt: prompt, active_job_id: "test-create", started_at: Time.current)
          sample = ruby_llm_evals_samples(:one)

          assert_difference "RubyLLM::Evals::PromptExecution.count", 1 do
            RubyLLM::Evals::ExecuteSampleJob.perform_now(run_id: run.id, sample_id: sample.id)
          end

          execution = RubyLLM::Evals::PromptExecution.find_by!(run: run, sample: sample)
          assert_equal run, execution.run
          assert_equal sample, execution.sample
        end
      end

      test "job executes prompt and stores result" do
        VCR.use_cassette("execute_sample_job_executes_prompt") do
          prompt = ruby_llm_evals_prompts(:two)
          run = RubyLLM::Evals::Run.create!(prompt: prompt, active_job_id: "test-execute", started_at: Time.current)
          sample = ruby_llm_evals_samples(:two)

          RubyLLM::Evals::ExecuteSampleJob.perform_now(run_id: run.id, sample_id: sample.id)

          execution = RubyLLM::Evals::PromptExecution.find_by!(run: run, sample: sample)
          assert_not_nil execution.message
          assert_not_nil execution.input
          assert_not_nil execution.output
          assert_not_nil execution.passed
        end
      end

      test "job copies sample configuration to prompt execution" do
        VCR.use_cassette("execute_sample_job_copies_sample_attributes") do
          prompt = ruby_llm_evals_prompts(:two)
          run = RubyLLM::Evals::Run.create!(prompt: prompt, active_job_id: "test-copy", started_at: Time.current)
          sample = ruby_llm_evals_samples(:two)

          RubyLLM::Evals::ExecuteSampleJob.perform_now(run_id: run.id, sample_id: sample.id)

          execution = RubyLLM::Evals::PromptExecution.find_by!(run: run, sample: sample)
          assert_equal sample.eval_type, execution.eval_type
          assert_equal sample.expected_output, execution.expected_output
          assert_equal sample.variables, execution.variables
        end
      end
    end
  end
end
