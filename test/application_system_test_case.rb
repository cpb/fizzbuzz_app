require "test_helper"
require "falcon/rackup/handler"

# Use Falcon as the Capybara server so system tests run on the same async
# event loop as the app — WebSockets, Action Cable, and async jobs all work
# naturally together without threading hacks.
Capybara.register_server(:falcon) do |app, port, host|
  Falcon::Rackup::Handler.run(app, Host: host, Port: port)
end

Capybara.server = :falcon

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]

  setup do
    WebMock.disable!
    ActiveJob::Base.queue_adapter = :async_job
  end

  teardown do
    WebMock.enable!
    ActiveJob::Base.queue_adapter = :test
  end
end
