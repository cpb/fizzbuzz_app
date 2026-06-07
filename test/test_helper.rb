ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "vcr"
require "webmock"

VCR.configure do |config|
  config.cassette_library_dir = "test/cassettes"
  config.hook_into :webmock
  config.filter_sensitive_data("<OLLAMA_API_BASE>") { RubyLLM.config.ollama_api_base }
end

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
    ActiveJob::Base.queue_adapter = :test
  end
end
