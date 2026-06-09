require "test_helper"

class SeedRoundTripTest < ActiveSupport::TestCase
  EVAL_FIXTURES = %w[
    fizzbuzz/prompts fizzbuzz/samples fizzbuzz/runs fizzbuzz/executions
    workbook/prompts workbook/samples workbook/runs workbook/executions
  ].freeze
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

    expected_by_model = Hash.new(0)
    EVAL_FIXTURES.each do |fixture_name|
      path = EVAL_BASE.join("#{fixture_name}.yml")
      yaml = YAML.safe_load(File.read(path), permitted_classes: [ Symbol, Time, ActiveSupport::TimeWithZone, ActiveSupport::TimeZone ], aliases: true) || {}
      model_class = yaml.dig("_fixture", "model_class").constantize
      expected_by_model[model_class] += yaml.except("_fixture").size
    end

    expected_by_model.each do |model_class, expected_count|
      assert_equal expected_count, model_class.count,
        "#{model_class} expected #{expected_count} records but DB has #{model_class.count}"
    end
  end
end
