require "test_helper"
require "evals/eval_test_case"

class WorkbookThinkingTrapEvalTest < EvalTestCase
  fixtures :"workbook/prompts", :"workbook/samples"

  setup do
    @runs = []
    @sample_labels = {}
    @eval_dir = "workbook"
  end

  teardown do
    EvalFixtureWriter.append(@eval_dir, @runs, sample_labels: @sample_labels, prompt_label: "thinking_trap_identification")
  end

  test "catastrophizing: correct identification affirmed" do
    run_eval(:catastrophizing_positive)
  end

  test "catastrophizing: wrong trap challenged" do
    run_eval(:catastrophizing_negative)
  end

  test "personalizing: correct identification affirmed" do
    run_eval(:personalizing_positive)
  end

  test "personalizing: wrong trap challenged" do
    run_eval(:personalizing_negative)
  end

  test "mind reading: correct identification affirmed" do
    run_eval(:mind_reading_positive)
  end

  test "mind reading: wrong trap challenged" do
    run_eval(:mind_reading_negative)
  end

  test "all or nothing: correct identification affirmed" do
    run_eval(:all_or_nothing_positive)
  end

  test "all or nothing: wrong trap challenged" do
    run_eval(:all_or_nothing_negative)
  end

  test "fortune telling: correct identification affirmed" do
    run_eval(:fortune_telling_positive)
  end

  test "fortune telling: wrong trap challenged" do
    run_eval(:fortune_telling_negative)
  end

  test "emotional reasoning: correct identification affirmed" do
    run_eval(:emotional_reasoning_positive)
  end

  test "emotional reasoning: wrong trap challenged" do
    run_eval(:emotional_reasoning_negative)
  end

  test "should statements: correct identification affirmed" do
    run_eval(:should_statements_positive)
  end

  test "should statements: wrong trap challenged" do
    run_eval(:should_statements_negative)
  end

  test "labeling: correct identification affirmed" do
    run_eval(:labeling_positive)
  end

  test "labeling: wrong trap challenged" do
    run_eval(:labeling_negative)
  end

  test "mental filter: correct identification affirmed" do
    run_eval(:mental_filter_positive)
  end

  test "mental filter: wrong trap challenged" do
    run_eval(:mental_filter_negative)
  end

  test "overgeneralizing: correct identification affirmed" do
    run_eval(:overgeneralizing_positive)
  end

  test "overgeneralizing: wrong trap challenged" do
    run_eval(:overgeneralizing_negative)
  end

  private

  def run_eval(sample_key)
    prompt = workbook_prompts(:thinking_trap_identification)
    sample = workbook_samples(sample_key)
    @sample_labels[sample.id] = sample_key
    run = RubyLLM::Evals::Run.create!(prompt: prompt, active_job_id: "test-#{SecureRandom.hex(4)}", started_at: Time.current)
    @runs << run

    with_eval_cassette(sample_key.to_s) do
      RubyLLM::Evals::ExecuteSampleJob.perform_now(run_id: run.id, sample_id: sample.id)
    end

    execution = run.prompt_executions.find_by!(sample: sample)
    assert execution.passed, "Sample #{sample_key} should pass (got: #{execution.message.inspect})"
  end
end
