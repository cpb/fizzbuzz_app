require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400]

  setup do
    # System tests need jobs to actually execute and broadcast via Turbo Streams.
    # The global :test adapter (set in test_helper.rb) queues but never runs jobs.
    ActiveJob::Base.queue_adapter = :async
  end

  teardown do
    ActiveJob::Base.queue_adapter = :test
  end
end
