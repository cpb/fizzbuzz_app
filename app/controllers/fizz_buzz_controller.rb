class FizzBuzzController < ApplicationController
  def start
  end

  def create
    # Redirect to the page where Hotwire will update the results
    # We pass the integer as a parameter to the page
    redirect_to start_fizz_buzz_path(starting_integer: params[:starting_integer])
    FizzBuzzJob.perform_later(params[:starting_integer].to_i)
  end
end
