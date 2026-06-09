class ThinkingTrapEvaluationJob < ApplicationJob
  def perform(session_id, traps)
    ActionCable.server.broadcast(
      "thinking_trap_evaluation_channel:#{session_id}",
      { type: "challenge", traps: Array(traps) }.to_json
    )
  end
end
