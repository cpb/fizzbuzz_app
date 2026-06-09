require "test_helper"

class ThinkingTrapEvaluationTest < ActiveSupport::TestCase
  def workbook_session
    @workbook_session ||= WorkbookSession.create!(
      current_step: "identify_situation",
      situation_description: "My manager criticized my code in front of the team."
    )
  end

  test "valid with workbook_session, submitted_traps, and outcome" do
    evaluation = ThinkingTrapEvaluation.new(
      workbook_session: workbook_session,
      submitted_traps: '["mind_reading", "catastrophizing"]',
      outcome: "affirm"
    )
    assert evaluation.valid?
  end

  test "invalid without outcome" do
    evaluation = ThinkingTrapEvaluation.new(
      workbook_session: workbook_session,
      submitted_traps: '["mind_reading"]'
    )
    refute evaluation.valid?
  end
end
