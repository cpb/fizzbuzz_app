require "test_helper"

class FizzBuzzJobTest < ActiveJob::TestCase
  include ActionCable::TestHelper

  test "performs the job and enqueues the next one" do
    assert_enqueued_with(job: FizzBuzzJob, args: [2]) do
      FizzBuzzJob.perform_now(1)
    end
  end

  test "broadcasts the correct result" do
    assert_broadcast_on("fizz_buzz_channel", { result: "Fizz" }) do
      FizzBuzzJob.perform_now(3)
    end
  end
end
