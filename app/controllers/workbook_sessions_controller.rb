class WorkbookSessionsController < ApplicationController
  before_action :set_session, only: [ :edit, :update ]

  def new
    @workbook_session = WorkbookSession.new(current_step: "intro")
  end

  def create
    @workbook_session = WorkbookSession.create!(current_step: "suds_initial")
    redirect_to edit_workbook_session_path(@workbook_session)
  end

  def edit
  end

  def update
    if params[:direction] == "back"
      @workbook_session.update!(current_step: @workbook_session.prev_step)
    else
      @workbook_session.assign_attributes(session_params)
      @workbook_session.current_step = @workbook_session.next_step
      @workbook_session.save!
    end
    respond_to { |format| format.turbo_stream }
  end

  private

  def set_session
    @workbook_session = WorkbookSession.find(params[:id])
  end

  def session_params
    params.require(:workbook_session).permit(
      :suds_initial, :tipp_strategy, :suds_post_tipp,
      :situation_description, :primary_thought_id,
      :evidence_for, :evidence_against,
      :rational_response, :rational_believability,
      :review_direction, :dear_plan, :give_plan,
      biased_thoughts_attributes: [
        :id, :thought, :pre_believability, :post_believability, :position, :_destroy
      ]
    )
  end
end
