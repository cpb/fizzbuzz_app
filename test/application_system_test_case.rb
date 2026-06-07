require "test_helper"
require "falcon/rackup/handler"
require "capybara/playwright"

# Use Falcon as the Capybara server so system tests run on the same async
# event loop as the app — WebSockets, Action Cable, and async jobs all work
# naturally together without threading hacks.
Capybara.register_server(:falcon) do |app, port, host|
  Falcon::Rackup::Handler.run(app, Host: host, Port: port)
end

Capybara.server = :falcon

Capybara.register_driver(:playwright_chromium) do |app|
  Capybara::Playwright::Driver.new(app,
    playwright_cli_executable_path: "npx playwright",
    browser_type: :chromium,
    headless: true,
    viewport: { width: 1400, height: 1400 }
  )
end

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :playwright_chromium

  setup do
    # Use async_job (backed by Falcon's event loop) instead of the global :test
    # adapter so jobs actually execute and broadcast via Turbo Streams.
    ActiveJob::Base.queue_adapter = :async_job
  end

  teardown do
    ActiveJob::Base.queue_adapter = :test
  end
end
