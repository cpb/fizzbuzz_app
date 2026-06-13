require "test_helper"
require "eval_loader"

class EvalLoaderTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  setup do
    RubyLLM::Evals::PromptExecution.delete_all
    RubyLLM::Evals::Run.delete_all
    RubyLLM::Evals::Sample.delete_all
    RubyLLM::Evals::Prompt.delete_all
  end

  test "seed_dir loads prompts from _fixture model_class, skipping _fixture entry itself" do
    Dir.mktmpdir do |tmpdir|
      write_fixtures(tmpdir)

      EvalLoader.seed_dir(tmpdir)

      assert_equal 2, RubyLLM::Evals::Prompt.count
      assert RubyLLM::Evals::Prompt.exists?(slug: "basic-prompt")
      assert RubyLLM::Evals::Prompt.exists?(slug: "hard-prompt")
    end
  end

  test "seed_dir loads samples linked to prompts by label" do
    Dir.mktmpdir do |tmpdir|
      write_fixtures(tmpdir)

      EvalLoader.seed_dir(tmpdir)

      basic = RubyLLM::Evals::Prompt.find_by!(slug: "basic-prompt")
      assert_equal 2, basic.samples.count

      hard = RubyLLM::Evals::Prompt.find_by!(slug: "hard-prompt")
      assert_equal 1, hard.samples.count
    end
  end

  test "seed_dir is idempotent — running twice does not duplicate records" do
    Dir.mktmpdir do |tmpdir|
      write_fixtures(tmpdir)

      EvalLoader.seed_dir(tmpdir)
      EvalLoader.seed_dir(tmpdir)

      assert_equal 2, RubyLLM::Evals::Prompt.count
      assert_equal 3, RubyLLM::Evals::Sample.count
    end
  end

  test "seed_dir returns early when prompts file is missing" do
    Dir.mktmpdir do |tmpdir|
      FileUtils.touch(File.join(tmpdir, "samples.yml"))

      assert_nothing_raised { EvalLoader.seed_dir(tmpdir) }
      assert_equal 0, RubyLLM::Evals::Prompt.count
    end
  end

  private

  def write_fixtures(dir)
    File.write(File.join(dir, "prompts.yml"), <<~YAML)
      ---
      _fixture:
        model_class: RubyLLM::Evals::Prompt
      basic_prompt:
        name: Basic Prompt
        slug: basic-prompt
        provider: ollama
        model: llama3.2
        message: "Is {{number}} divisible by 3?"
      hard_prompt:
        name: Hard Prompt
        slug: hard-prompt
        provider: ollama
        model: llama3.2
        message: "FizzBuzz {{number}}"
    YAML

    File.write(File.join(dir, "samples.yml"), <<~YAML)
      ---
      _fixture:
        model_class: RubyLLM::Evals::Sample
      basic_3:
        prompt: basic_prompt
        eval_type: exact
        expected_output: "yes"
        variables:
          number: "3"
      basic_5:
        prompt: basic_prompt
        eval_type: exact
        expected_output: "no"
        variables:
          number: "5"
      hard_15:
        prompt: hard_prompt
        eval_type: contains
        expected_output: FizzBuzz
        variables:
          number: "15"
    YAML
  end
end
