require "test_helper"

class FizzBuzzControllerTest < ActionDispatch::IntegrationTest
  test "should get start" do
    get root_url
    assert_response :success
  end

  test "should enqueue job on post" do
    # Controller enqueues starting - 1 (first result rendered synchronously)
    # with a 1-second delay so the browser WebSocket reconnects first.
    assert_enqueued_with(job: FizzBuzzJob, args: [ 4 ]) do
      post root_url, params: { starting_integer: 5 }
    end
    assert_response :redirect
  end

  test "should not enqueue job when starting at 1" do
    assert_no_enqueued_jobs do
      post root_url, params: { starting_integer: 1 }
    end
    assert_response :redirect
  end

  test "generates a unique tab_token in redirect URL and passes it to FizzBuzzJob" do
    post root_url, params: { starting_integer: 5 }
    redirect_params = Rack::Utils.parse_query(URI.parse(response.location).query)
    tab_token = redirect_params["tab_token"]
    assert_not_nil tab_token, "redirect URL should include a tab_token param"
    assert_match(/\A[0-9a-f\-]{36}\z/, tab_token)
    assert_equal tab_token, enqueued_jobs.last[:args][1]
  end
end
