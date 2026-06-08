require "test_helper"
require "support/eval_fixture_writer"

class EvalTestCase < ActiveSupport::TestCase
  self.use_transactional_tests = false   # teardown must read DB records

  setup do
    # Subclasses call EvalLoader.seed_dir("fizzbuzz") in their own setup
  end

  teardown do
    # Subclasses define @eval_dir and @runs for EvalFixtureWriter.append
  end

  def with_eval_cassette(name, &block)
    if ENV["SKIP_VCR"]
      yield  # hit real Ollama, no cassette
    elsif ENV["RECORD_EVALS"]
      VCR.use_cassette(name, record: :all, &block)  # re-record
    else
      VCR.use_cassette(name, record: :new_episodes, &block)  # use existing
    end
  end
end
