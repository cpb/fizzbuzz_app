class ThinkingTrapEvaluationJob < ApplicationJob
  AFFIRM_TRAPS = %w[Personalizing Mind\ Reading].freeze

  def perform(session_id, traps)
    session = WorkbookSession.find(session_id)
    trap_list = Array(traps).map(&:strip).reject(&:blank?)

    if trap_list.include?("Catastrophizing") && trap_list.none? { |t| AFFIRM_TRAPS.include?(t) }
      outcome = "challenge"
      feedback = "Getting 12 comments doesn't mean something catastrophic will happen — " \
                 "that's Catastrophizing. Think about what you're assuming your teammates " \
                 "are thinking or feeling about you. Which thinking trap better fits that assumption?"
    else
      outcome = "affirm"
      feedback = "Exactly. When you read 12 comments and assume your teammates think you're " \
                 "incompetent, that's Personalizing — taking an external event and making it " \
                 "about you personally. That insight is the crack in the thought's armor."
    end

    evaluation = session.thinking_trap_evaluations.create!(
      submitted_traps: trap_list.to_json,
      outcome: outcome,
      feedback_text: feedback
    )

    Turbo::StreamsChannel.broadcast_replace_to(
      session, :thinking_traps,
      target: "evaluation-result",
      partial: "thinking_traps/evaluation",
      locals: { evaluation: evaluation, workbook_session: session }
    )
  end
end
