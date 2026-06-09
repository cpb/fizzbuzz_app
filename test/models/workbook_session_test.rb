require "test_helper"

class WorkbookSessionTest < ActiveSupport::TestCase
  test "valid with current_step and situation_description" do
    session = WorkbookSession.new(
      current_step: "identify_situation",
      situation_description: "My manager criticized my code in front of the team."
    )
    assert session.valid?
  end

  test "invalid without current_step" do
    session = WorkbookSession.new(
      situation_description: "My manager criticized my code in front of the team."
    )
    refute session.valid?
  end
end
