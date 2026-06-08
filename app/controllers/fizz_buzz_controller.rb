class FizzBuzzController < ApplicationController
  def start
  end

  def create
    starting = params[:starting_integer].to_i
    tab_token = SecureRandom.uuid
    redirect_to root_path(starting_integer: starting, tab_token: tab_token, use_llm: params[:use_llm])
    if starting >= 1
      job_class = params[:use_llm].present? ? LLMFizzBuzzJob : FizzBuzzJob
      job_class.set(wait: 1.second).perform_later(starting, tab_token)
    end
  end
end
