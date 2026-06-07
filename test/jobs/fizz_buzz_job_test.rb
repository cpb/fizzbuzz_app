require "test_helper"

class FizzBuzzJobTest < ActiveJob::TestCase
  include ActionCable::TestHelper

  test "performs the job and enqueues the next one (counting down)" do
    assert_enqueued_with(job: FizzBuzzJob, args: [ 4 ]) do
      FizzBuzzJob.perform_now(5)
    end
  end

  test "does not enqueue another job when number is 1" do
    assert_no_enqueued_jobs do
      FizzBuzzJob.perform_now(1)
    end
  end

  test "broadcasts the correct result" do
    assert_broadcasts("fizz_buzz_channel", 1) do
      FizzBuzzJob.perform_now(3)
    end
    assert_match "Fizz", broadcasts("fizz_buzz_channel").last
  end
end
