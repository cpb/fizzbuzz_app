class SurveysController < ApplicationController
  def show
    @response = SurveyResponse.new(submitted_at: Time.current)
  end

  def create
    @response = SurveyResponse.new(survey_params.merge(submitted_at: Time.current))
    if @response.save
      stats = SurveyResponse.aggregate_stats
      Turbo::StreamsChannel.broadcast_replace_to(
        :survey_results,
        target: "results_panel",
        partial: "surveys/results_panel",
        locals: { stats: stats }
      )
      redirect_to results_survey_path, notice: "Response recorded — thank you!"
    else
      render :show, status: :unprocessable_entity
    end
  end

  def results
    @stats = SurveyResponse.aggregate_stats
  end

  private

  def survey_params
    permitted = params.require(:survey_response).permit(
      :location, :role, :writes_ruby, :paid_to_write_ruby,
      :years_of_experience, :prior_experience, :team_ai_adoption,
      :likert_overhyped, :likert_frustrated, :likert_limit_to_boilerplate,
      :likert_anxious, :likert_made_peace, :likert_more_capable
    )
    permitted[:ai_tools] = Array(params.dig(:survey_response, :ai_tools))
                             .select { |t| SurveyResponse::AI_TOOL_OPTIONS.include?(t) }
    permitted
  end
end
