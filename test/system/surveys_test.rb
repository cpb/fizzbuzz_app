require "application_system_test_case"

class SurveysTest < ApplicationSystemTestCase
  test "submitting the survey" do
    visit survey_path

    choose "Developer"
    choose "Yes", name: "survey_response[writes_ruby]"
    choose "Yes", name: "survey_response[paid_to_write_ruby]"
    choose "1 3", name: "survey_response[years_of_experience]"
    choose "2 5", name: "survey_response[prior_experience]"
    choose "Regularly integrated", name: "survey_response[team_ai_adoption]"

    # Check boxes
    check "Claude code cli"
    check "Cursor"

    # Likert scale
    choose "likert_overhyped_1"
    choose "likert_frustrated_1"
    choose "likert_limit_to_boilerplate_1"
    choose "likert_anxious_1"
    choose "likert_made_peace_5"
    choose "likert_more_capable_5"

    click_on "Submit Survey"
    sleep 1
    assert_text "Response recorded — thank you!"
    assert_current_path results_survey_path
    assert_text "1 response so far"
  end
end
