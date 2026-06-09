class ThinkingTrapsController < ApplicationController
  def create
    ThinkingTrapEvaluationJob.set(wait: 1.second).perform_later(params[:workbook_session_id], params[:thinking_trap])
    respond_to do |format|
      format.turbo_stream
    end
  end
end
