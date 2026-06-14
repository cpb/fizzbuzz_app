ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "vcr"
require "webmock/minitest"
require "support/cassette_prefix"
require "support/application_test_case"
require "support/application_controller_test_case"
require "support/application_job_test_case"
require "support/application_view_test_case"

WebMock.disable_net_connect!(allow_localhost: [ "127.0.0.1", "localhost" ])

VCR.configure do |config|
  config.cassette_library_dir = Rails.root.to_s
  config.hook_into :webmock
  config.ignore_hosts "127.0.0.1"
  config.filter_sensitive_data("<OLLAMA_API_BASE>") { RubyLLM.config.ollama_api_base }
end

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    self.fixture_paths += Dir[Rails.root.join("packs/*/test/fixtures")]

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
    ActiveJob::Base.queue_adapter = :test
  end
end

# rails/test_help copies fixture_paths to IntegrationTest via an on_load hook,
# creating a separate copy that doesn't inherit further changes to TestCase.
ActionDispatch::IntegrationTest.fixture_paths += Dir[Rails.root.join("packs/*/test/fixtures")]
