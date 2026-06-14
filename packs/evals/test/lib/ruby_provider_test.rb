require "test_helper"

class RubyProviderTest < ApplicationTestCase
  self.fixture_table_names = []

  test "executing a sample against a ruby-provider prompt passes variables to the code and uses the return value as the model response" do
    prompt = RubyLLM::Evals::Prompt.create!(
      provider: "ruby",
      model: "ruby",
      message: "variables[:number].to_i * 2",
      name: "Ruby double",
      slug: "ruby-double"
    )

    sample = RubyLLM::Evals::Sample.create!(
      prompt: prompt,
      variables: { "number" => "3" },
      eval_type: "exact",
      expected_output: "6"
    )

    run = RubyLLM::Evals::Run.create!(
      prompt: prompt,
      active_job_id: "ruby-provider-test",
      started_at: Time.current
    )

    execution = RubyLLM::Evals::PromptExecution.create!(
      run: run,
      sample: sample,
      active_job_id: "ruby-provider-execution-test"
    )

    execution.execute

    assert_equal "6", execution.message
    assert_equal true, execution.passed
  end

  test "executing code that references Rails raises NameError (clean binding)" do
    assert_raises(NameError) do
      RubyProvider.call(code: "Rails", variables: {})
    end
  end
end
