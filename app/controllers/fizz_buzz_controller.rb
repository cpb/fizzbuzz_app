class FizzBuzzController < ApplicationController
  def start
  end

  def create
    starting = params[:starting_integer].to_i
    # Redirect back to start, which renders the first result synchronously.
    # The job picks up from the next number to avoid a broadcast race with reconnection.
    redirect_to start_fizz_buzz_path(starting_integer: starting)
    # Wait 1 second before the first broadcast so the browser has time to
    # load the redirected page and re-establish its WebSocket connection.
    FizzBuzzJob.set(wait: 1.second).perform_later(starting - 1) if starting > 1
  end
end
