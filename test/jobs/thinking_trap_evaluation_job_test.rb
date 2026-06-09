require "test_helper"

class ThinkingTrapEvaluationJobTest < ActiveJob::TestCase
  test "creates a challenge evaluation when Catastrophizing is the only trap selected" do
    session = WorkbookSession.create!(current_step: "select_trap")
    ThinkingTrapEvaluationJob.perform_now(session.id, [ "Catastrophizing" ])

    evaluation = session.thinking_trap_evaluations.last
    assert_equal "challenge", evaluation.outcome
    assert_match "Catastrophizing", evaluation.feedback_text
  end

  test "creates an affirm evaluation when Personalizing is selected" do
    session = WorkbookSession.create!(current_step: "select_trap")
    ThinkingTrapEvaluationJob.perform_now(session.id, [ "Personalizing" ])

    evaluation = session.thinking_trap_evaluations.last
    assert_equal "affirm", evaluation.outcome
  end

  test "creates an affirm evaluation when both Catastrophizing and Personalizing are selected" do
    session = WorkbookSession.create!(current_step: "select_trap")
    ThinkingTrapEvaluationJob.perform_now(session.id, [ "Catastrophizing", "Personalizing" ])

    evaluation = session.thinking_trap_evaluations.last
    assert_equal "affirm", evaluation.outcome
  end
end
