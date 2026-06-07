class LlmFizzBuzzJob < ApplicationJob
  queue_as :default

  def perform(number, tab_token)
    result = LlmFizzBuzzer.call(number)
    Turbo::StreamsChannel.broadcast_append_to(
      "fizz_buzz_channel:#{tab_token}",
      target: "results",
      partial: "fizz_buzz/result",
      locals: { result: result }
    )
    sleep 1
    LlmFizzBuzzJob.perform_later(number - 1, tab_token) if number > 1
  end
end
