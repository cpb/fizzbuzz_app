class LLMFizzBuzzJob < ApplicationJob
  queue_as :default

  def perform(number, tab_token)
    result = LLMFizzBuzzer.call(number)
    Turbo::StreamsChannel.broadcast_prepend_to(
      "fizz_buzz_channel:#{tab_token}",
      target: "results",
      partial: "fizz_buzz/result",
      locals: { result: result }
    )
    # sleep 1
    LLMFizzBuzzJob.set(wait: 1.second).perform_later(number - 1, tab_token) if number > 1
  end
end
