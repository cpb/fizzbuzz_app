require "test_helper"
require "support/eval_fixture_writer"

class EvalTestCase < ActiveSupport::TestCase
  self.fixture_paths = [ Rails.root.join("evals") ]
  self.fixture_table_names = []
  self.use_transactional_tests = false

  parallelize(workers: 1)

  def before_setup
    RubyLLM::Evals::PromptExecution.delete_all
    RubyLLM::Evals::Run.delete_all
    super
  end

  def with_eval_cassette(name, &block)
    if ENV["SKIP_VCR"]
      VCR.turned_off(&block)
    elsif ENV["RECORD_EVALS"]
      VCR.use_cassette(name, record: :all, &block)
    else
      VCR.use_cassette(name, record: :new_episodes, &block)
    end
  end
end
