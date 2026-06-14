require "test_helper"

class SurveysControllerTest < ApplicationControllerTestCase
  test "GET /survey returns success" do
    get survey_url
    assert_response :success
  end

  test "POST /survey with valid params creates response and redirects" do
    assert_difference("SurveyResponse.count", 1) do
      post survey_url, params: { survey_response: {
        location: "New York",
        role: "developer",
        writes_ruby: true,
        paid_to_write_ruby: "yes",
        years_of_experience: "1_3",
        prior_experience: "2_5",
        team_ai_adoption: "regularly_integrated",
        ai_tools: [ "claude_code_cli" ]
      } }
    end
    assert_redirected_to results_survey_path
  end

  test "POST /survey with missing required param renders show" do
    post survey_url, params: { survey_response: { role: "" } }
    assert_response :unprocessable_entity
  end

  test "GET /survey/results returns success" do
    get results_survey_url
    assert_response :success
  end
end
