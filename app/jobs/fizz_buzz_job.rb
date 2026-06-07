class FizzBuzzJob < ApplicationJob
  queue_as :default

  def perform(number, tab_token = nil)
    result = FizzBuzzer.call(number)
    Turbo::StreamsChannel.broadcast_append_to(
      "fizz_buzz_channel",
      target: "results",
      partial: "fizz_buzz/result",
      locals: { result: result }
    )
    sleep 1
    FizzBuzzJob.perform_later(number - 1) if number > 1
  end
end
