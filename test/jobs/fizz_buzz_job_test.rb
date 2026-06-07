require "test_helper"

class FizzBuzzJobTest < ActiveJob::TestCase
  include ActionCable::TestHelper

  test "performs the job and enqueues the next one (counting down)" do
    assert_enqueued_with(job: FizzBuzzJob, args: [ 4, "tok" ]) do
      FizzBuzzJob.perform_now(5, "tok")
    end
  end

  test "does not enqueue another job when number is 1" do
    assert_no_enqueued_jobs do
      FizzBuzzJob.perform_now(1, "tok")
    end
  end

  test "broadcasts the correct result" do
    assert_broadcasts("fizz_buzz_channel:tok", 1) do
      FizzBuzzJob.perform_now(3, "tok")
    end
    assert_match "Fizz", broadcasts("fizz_buzz_channel:tok").last
  end

  test "broadcasts to tab-scoped channel and carries token through countdown" do
    tab_token = "test-tab-token"
    assert_broadcasts("fizz_buzz_channel:#{tab_token}", 1) do
      assert_enqueued_with(job: FizzBuzzJob, args: [ 4, tab_token ]) do
        FizzBuzzJob.perform_now(5, tab_token)
      end
    end
    assert_no_broadcasts("fizz_buzz_channel")
  end
end
