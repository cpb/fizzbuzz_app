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
      write_support_fixtures(tmpdir)

      prompt, sample = create_prompt_and_sample
      run = RubyLLM::Evals::Run.create!(prompt: prompt, active_job_id: "test-abc", started_at: Time.current)
      RubyLLM::Evals::PromptExecution.create!(
        run: run, sample: sample,
        active_job_id: "exec-abc", eval_type: "contains",
        expected_output: "Fizz", message: "Fizz", passed: true
      )

      EvalFixtureWriter.append(tmpdir, [ run ],
        prompt_label: "eval_writer_prompt",
        sample_labels: { sample.id => "eval_writer_sample" })

      RubyLLM::Evals::PromptExecution.delete_all
      RubyLLM::Evals::Run.delete_all
      RubyLLM::Evals::Sample.delete_all
      RubyLLM::Evals::Prompt.delete_all

      ActiveRecord::FixtureSet.create_fixtures(tmpdir, %w[prompts samples runs executions])

      assert_equal 1, RubyLLM::Evals::Run.count
      assert_equal 1, RubyLLM::Evals::PromptExecution.count
    end
  end

  test "append accumulates multiple runs without clobbering existing entries" do
    Dir.mktmpdir do |tmpdir|
      write_support_fixtures(tmpdir)

      prompt, sample = create_prompt_and_sample

      run1 = RubyLLM::Evals::Run.create!(prompt: prompt, active_job_id: "test-run1", started_at: Time.current)
      RubyLLM::Evals::PromptExecution.create!(
        run: run1, sample: sample,
        active_job_id: "exec-run1", eval_type: "contains",
        expected_output: "Fizz", message: "Fizz", passed: true
      )

      run2 = RubyLLM::Evals::Run.create!(prompt: prompt, active_job_id: "test-run2", started_at: Time.current)
      RubyLLM::Evals::PromptExecution.create!(
        run: run2, sample: sample,
        active_job_id: "exec-run2", eval_type: "contains",
        expected_output: "Fizz", message: "Fizz", passed: true
      )

      EvalFixtureWriter.append(tmpdir, [ run1 ],
        prompt_label: "eval_writer_prompt",
        sample_labels: { sample.id => "eval_writer_sample" })
      EvalFixtureWriter.append(tmpdir, [ run2 ],
        prompt_label: "eval_writer_prompt",
        sample_labels: { sample.id => "eval_writer_sample" })

      RubyLLM::Evals::PromptExecution.delete_all
      RubyLLM::Evals::Run.delete_all
      RubyLLM::Evals::Sample.delete_all
      RubyLLM::Evals::Prompt.delete_all

      ActiveRecord::FixtureSet.create_fixtures(tmpdir, %w[prompts samples runs executions])

      assert_equal 2, RubyLLM::Evals::Run.count
      assert_equal 2, RubyLLM::Evals::PromptExecution.count
    end
  end

  private

  def write_support_fixtures(tmpdir)
    File.write(File.join(tmpdir, "prompts.yml"), <<~YAML)
      ---
      _fixture:
        model_class: RubyLLM::Evals::Prompt
      eval_writer_prompt:
        name: EvalWriter Test Prompt
        slug: eval-writer-test
        provider: ollama
        model: llama3.2
        message: "{{number}}"
    YAML

    File.write(File.join(tmpdir, "samples.yml"), <<~YAML)
      ---
      _fixture:
        model_class: RubyLLM::Evals::Sample
      eval_writer_sample:
        prompt: eval_writer_prompt
        eval_type: contains
        expected_output: Fizz
        variables:
          number: "3"
    YAML
  end

  def create_prompt_and_sample
    prompt = RubyLLM::Evals::Prompt.create!(
      name: "EvalWriter Test Prompt", slug: "eval-writer-test",
      provider: "ollama", model: "llama3.2", message: "{{number}}"
    )
    sample = RubyLLM::Evals::Sample.create!(
      prompt: prompt, eval_type: "contains", expected_output: "Fizz",
      variables: { "number" => "3" }
    )
    [ prompt, sample ]
  end
end
