class FizzBuzzController < ApplicationController
  def start
  end

  def create
    starting = params[:starting_integer].to_i
    tab_token = SecureRandom.uuid
    redirect_to root_path(starting_integer: starting, tab_token: tab_token)
    FizzBuzzJob.set(wait: 1.second).perform_later(starting - 1, tab_token) if starting > 1
  end
end
