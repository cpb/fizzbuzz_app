require "test_helper"

class FizzBuzzControllerTest < ActionDispatch::IntegrationTest
  test "should get start" do
    get start_fizz_buzz_url
    assert_response :success
  end

  test "should enqueue job on post" do
    assert_enqueued_with(job: FizzBuzzJob, args: [1]) do
      post start_fizz_buzz_url, params: { starting_integer: 1 }
    end
    assert_response :redirect
  end
end
