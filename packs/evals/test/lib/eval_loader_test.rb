require "test_helper"

class EvalLoaderTest < ApplicationTestCase
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

  test "seed_dir loads a ruby-provider prompt without error" do
    Dir.mktmpdir do |tmpdir|
      write_ruby_fixtures(tmpdir)

      assert_nothing_raised { EvalLoader.seed_dir(tmpdir) }

      prompt = RubyLLM::Evals::Prompt.find_by!(provider: "ruby")
      assert_equal RubyProvider, EvalLoader.provider_for(prompt), "Expected EvalLoader.provider_for to return RubyProvider for a ruby-provider prompt"
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
        message: "Is {{number}} prime?"
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
      hard_7:
        prompt: hard_prompt
        eval_type: contains
        expected_output: prime
        variables:
          number: "7"
    YAML
  end

  def write_ruby_fixtures(dir)
    File.write(File.join(dir, "prompts.yml"), <<~YAML)
      ---
      _fixture:
        model_class: RubyLLM::Evals::Prompt
      ruby_double:
        name: Ruby Double
        slug: ruby-double
        provider: ruby
        model: ruby
        message: "variables[:number].to_i * 2"
    YAML

    File.write(File.join(dir, "samples.yml"), <<~YAML)
      ---
      _fixture:
        model_class: RubyLLM::Evals::Sample
      ruby_double_3:
        prompt: ruby_double
        eval_type: exact
        expected_output: "6"
        variables:
          number: "3"
    YAML
  end
end
