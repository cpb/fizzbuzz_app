require "test_helper"

class ThinkingTrapEvaluationJobTest < ActiveJob::TestCase
  include ActionCable::TestHelper

  test "broadcasts a challenge when Catastrophizing is in selected traps" do
    session_id = "session-abc"
    assert_broadcasts("thinking_trap_evaluation_channel:#{session_id}", 1) do
      ThinkingTrapEvaluationJob.perform_now(session_id, [ "Catastrophizing", "Mind Reading" ])
    end
    assert_match "challenge", broadcasts("thinking_trap_evaluation_channel:#{session_id}").last
  end
end
