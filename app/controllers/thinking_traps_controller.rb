class ThinkingTrapsController < ApplicationController
  def create
    ThinkingTrapEvaluationJob.perform_later(params[:workbook_session_id], params[:thinking_trap])
    respond_to do |format|
      format.turbo_stream
    end
  end
end
