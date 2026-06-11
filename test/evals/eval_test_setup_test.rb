require "test_helper"
require "support/eval_test_setup"

class EvalTestSetupTest < ActiveSupport::TestCase
  include EvalTestSetup
  fixtures :"fizzbuzz/prompts", :"fizzbuzz/samples"

  setup do
    @runs = []
    @sample_labels = {}
    @eval_dir = Dir.mktmpdir
    @prompt_label = "fizzbuzz_basic"
  end

  teardown do
    FileUtils.rm_rf(@eval_dir)
  end

  test "with_eval_cassette does not write fixture YAML during cassette playback" do
    with_eval_cassette("fizzbuzz_basic_15") { }
    assert Dir.glob(File.join(@eval_dir, "*.yml")).empty?,
      "No YAML files should be written during cassette playback"
  end

  test "with_eval_cassette writes fixture YAML when cassette records new interactions" do
    cassette_path = Rails.root.join("test/cassettes/eval_setup_recording.yml")
    FileUtils.rm_f(cassette_path)

    prompt = RubyLLM::Evals::Prompt.create!(
      name: "EvalSetup Test", slug: "eval-setup-test",
      provider: "ollama", model: "llama3.2", message: "{{n}}"
    )
    sample = RubyLLM::Evals::Sample.create!(
      prompt: prompt, eval_type: "contains",
      expected_output: "Fizz", variables: { "n" => "3" }
    )
    run = RubyLLM::Evals::Run.create!(
      prompt: prompt, active_job_id: "eval-setup-run", started_at: Time.current
    )
    RubyLLM::Evals::PromptExecution.create!(
      run: run, sample: sample, active_job_id: "eval-setup-exec",
      eval_type: "contains", expected_output: "Fizz", message: "Fizz", passed: true
    )

    @runs = [ run ]
    @sample_labels = { sample.id => "eval_setup_sample" }
    @prompt_label = "eval_setup_prompt"

    with_eval_cassette("eval_setup_recording") do
      Net::HTTP.get(URI("http://cpb.ca/"))
    end

    refute Dir.glob(File.join(@eval_dir, "*.yml")).empty?,
      "YAML files should be written when cassette records new interactions"
  ensure
    FileUtils.rm_f(cassette_path)
  end
end
