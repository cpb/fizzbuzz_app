require "test_helper"
require "support/eval_fixture_writer"

class EvalFixtureWriterTest < ActiveSupport::TestCase
  self.fixture_table_names = []
  self.use_transactional_tests = false

  def before_setup
    RubyLLM::Evals::PromptExecution.delete_all
    RubyLLM::Evals::Run.delete_all
    RubyLLM::Evals::Sample.delete_all
    RubyLLM::Evals::Prompt.delete_all
    super
  end

  test "round-trips run and execution to YAML and back to the database" do
    Dir.mktmpdir do |tmpdir|
      File.write(File.join(tmpdir, "prompts.yml"), {
        "_fixture" => { "model_class" => "RubyLLM::Evals::Prompt" },
        "test_prompt" => { "name" => "Test", "slug" => "test-prompt", "provider" => "ollama", "model" => "llama3.2", "message" => "{{number}}" }
      }.to_yaml)
      File.write(File.join(tmpdir, "samples.yml"), {
        "_fixture" => { "model_class" => "RubyLLM::Evals::Sample" },
        "test_sample" => { "prompt" => "test_prompt", "eval_type" => "contains", "expected_output" => "Fizz", "variables" => { "number" => "3" } }
      }.to_yaml)

      # Create records directly to avoid fixture cache conflicts on the round-trip load below
      prompt = RubyLLM::Evals::Prompt.create!(name: "Test", slug: "test-prompt", provider: "ollama", model: "llama3.2", message: "{{number}}")
      sample = RubyLLM::Evals::Sample.create!(prompt: prompt, eval_type: "contains", expected_output: "Fizz", variables: { "number" => "3" })
      run = RubyLLM::Evals::Run.create!(prompt: prompt, active_job_id: "test-abc", started_at: Time.current)
      RubyLLM::Evals::PromptExecution.create!(
        run: run, sample: sample,
        active_job_id: "exec-abc", eval_type: "contains",
        expected_output: "Fizz", message: "Fizz", passed: true
      )

      EvalFixtureWriter.append(tmpdir, [ run ],
        prompt_label: "test_prompt",
        sample_labels: { sample.id => "test_sample" })

      RubyLLM::Evals::PromptExecution.delete_all
      RubyLLM::Evals::Run.delete_all
      RubyLLM::Evals::Sample.delete_all
      RubyLLM::Evals::Prompt.delete_all

      ActiveRecord::FixtureSet.create_fixtures(tmpdir, %w[prompts samples runs executions])

      assert_equal 1, RubyLLM::Evals::Run.count
      assert_equal 1, RubyLLM::Evals::PromptExecution.count
    end
  end
end
