require "test_helper"

class LLMFizzBuzzJobTest < ActiveJob::TestCase
  include ActionCable::TestHelper

  test "performs the job and enqueues the next one (counting down)" do
    assert_enqueued_with(job: LLMFizzBuzzJob, args: [ 4, "tok" ]) do
      LLMFizzBuzzJob.perform_now(5, "tok")
    end
  end

  test "does not enqueue another job when number is 1" do
    assert_no_enqueued_jobs do
      LLMFizzBuzzJob.perform_now(1, "tok")
    end
  end

  test "broadcasts to the tab-scoped channel" do
    assert_broadcasts("fizz_buzz_channel:tok", 1) do
      LLMFizzBuzzJob.perform_now(3, "tok")
    end
    assert_no_broadcasts("fizz_buzz_channel")
  end

  test "broadcasts to tab-scoped channel and carries token through countdown" do
    tab_token = "test-tab-token"
    assert_broadcasts("fizz_buzz_channel:#{tab_token}", 1) do
      assert_enqueued_with(job: LLMFizzBuzzJob, args: [ 4, tab_token ]) do
        LLMFizzBuzzJob.perform_now(5, tab_token)
      end
    end
    assert_no_broadcasts("fizz_buzz_channel")
  end
end
