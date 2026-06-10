class DemoController < ApplicationController
  def show
    WorkbookSession.seed_auth_demo if WorkbookSession.auth_demo.nil?
    redirect_to new_workbook_session_url
  end
end
