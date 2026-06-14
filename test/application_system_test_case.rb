require "test_helper"
require "falcon/rackup/handler"

require "capybara/cuprite"

# Playwright's managed Chromium — already present in the remote environment,
# no installation step needed. Falls back to searching PATH if the known path
# doesn't exist (e.g. local dev where Chrome is installed normally).
CUPRITE_CHROME_PATH = "/opt/pw-browsers/chromium-1194/chrome-linux/chrome"

# Use Falcon as the Capybara server so system tests run on the same async
# event loop as the app — WebSockets, Action Cable, and async jobs all work
# naturally together without threading hacks.
Capybara.register_server(:falcon) do |app, port, host|
  Falcon::Rackup::Handler.run(app, Host: host, Port: port)
end

Capybara.server = :falcon

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  include CassettePrefix
  driven_by :cuprite, using: :chrome, screen_size: [ 1400, 1400 ], options: {
    browser_path: File.exist?(CUPRITE_CHROME_PATH) ? CUPRITE_CHROME_PATH : nil,
    headless: true,
    browser_options: { "no-sandbox": nil, "disable-gpu": nil }
  }

  setup do
    ActiveJob::Base.queue_adapter = :async_job
  end

  teardown do
    ActiveJob::Base.queue_adapter = :test
  end
end
