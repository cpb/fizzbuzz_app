require "test_helper"

class SeedRoundTripTest < ActiveSupport::TestCase
  EVAL_FIXTURES = %w[fizzbuzz/prompts fizzbuzz/samples fizzbuzz/runs fizzbuzz/executions].freeze
  EVAL_BASE = Rails.root.join("evals")

  self.use_transactional_tests = false

  def before_setup
    RubyLLM::Evals::PromptExecution.delete_all
    RubyLLM::Evals::Run.delete_all
    RubyLLM::Evals::Sample.delete_all
    RubyLLM::Evals::Prompt.delete_all
    super
  end

  test "all evals/ fixture files load without error" do
    assert_nothing_raised do
      ActiveRecord::FixtureSet.create_fixtures(EVAL_BASE, EVAL_FIXTURES)
    end
  end

  test "fixture counts match YAML records" do
    ActiveRecord::FixtureSet.create_fixtures(EVAL_BASE, EVAL_FIXTURES)

    EVAL_FIXTURES.each do |fixture_name|
      path = EVAL_BASE.join("#{fixture_name}.yml")
      yaml = YAML.safe_load(File.read(path), permitted_classes: [ Symbol, Time, ActiveSupport::TimeWithZone, ActiveSupport::TimeZone ], aliases: true) || {}
      expected_count = yaml.except("_fixture").size
      model_class = yaml.dig("_fixture", "model_class").constantize

      assert_equal expected_count, model_class.count,
        "#{fixture_name}.yml has #{expected_count} records but DB has #{model_class.count}"
    end
  end
end
