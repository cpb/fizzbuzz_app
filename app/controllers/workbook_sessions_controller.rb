class WorkbookSessionsController < ApplicationController
  def new
  end

  def create
    respond_to do |format|
      format.turbo_stream
    end
  end
end
