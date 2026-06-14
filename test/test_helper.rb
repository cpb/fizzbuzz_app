ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "vcr"
require "webmock/minitest"

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

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
    ActiveJob::Base.queue_adapter = :test

    # Resolves the cassette path relative to the calling test file's pack
    # (or root test/) directory: packs/*/test/cassettes/<name> or test/cassettes/<name>.
    # Pass caller_depth: 2 when calling through an intermediate helper method.
    def use_cassette(name, caller_depth: 1, **options, &block)
      location = caller_locations(caller_depth, 1).first
      relative = Pathname.new(location.absolute_path).relative_path_from(Rails.root).to_s
      parts = relative.split("/")
      test_idx = parts.rindex("test")
      prefix = parts[0..test_idx].join("/")
      VCR.use_cassette("#{prefix}/cassettes/#{name}", **options, &block)
    end
  end
end
