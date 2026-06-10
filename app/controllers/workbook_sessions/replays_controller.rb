module WorkbookSessions
  class ReplaysController < ApplicationController
    before_action :set_workbook_session

    def show
      @replay_step = first_replay_step
    end

    def advance
      @replay_step = next_replay_step(params[:replay_step])
      respond_to { |format| format.turbo_stream }
    end

    private

    STEP_FIELDS = {
      "suds_initial" => :suds_initial,
      "tipp" => :tipp_strategy,
      "describe_situation" => :situation_description,
      "rational_response" => :rational_response,
      "suds_final" => :suds_post_restructuring,
      "dear_give" => :review_direction,
      "dear_plan" => :dear_plan,
      "give_plan" => :give_plan
    }.freeze

    def set_workbook_session
      @workbook_session = WorkbookSession.find(params[:workbook_session_id])
    end

    def first_replay_step
      WorkbookSession::STEPS.find { |step| step_has_data?(step) } || WorkbookSession::STEPS.first
    end

    def step_has_data?(step)
      field = STEP_FIELDS[step]
      return false unless field
      @workbook_session.send(field).present?
    end

    def next_replay_step(step)
      steps = @workbook_session.send(:conditional_steps)
      idx = steps.index(step)
      steps[idx + 1] if idx
    end
  end
end
