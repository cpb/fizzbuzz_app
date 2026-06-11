require "support/eval_fixture_writer"

module EvalTestSetup
  extend ActiveSupport::Concern

  included do
    self.fixture_paths = [ Rails.root.join("evals") ]
    self.fixture_table_names = []
    self.use_transactional_tests = false

    parallelize(workers: 1)
  end

  def before_setup
    RubyLLM::Evals::PromptExecution.delete_all
    RubyLLM::Evals::Run.delete_all
    super
  end

  def with_eval_cassette(name)
    VCR.use_cassette(name, record: ENV["RECORD_EVALS"] ? :all : :new_episodes) do |cassette|
      yield
      if cassette.new_recorded_interactions.any?
        EvalFixtureWriter.append(@eval_dir, @runs, sample_labels: @sample_labels, prompt_label: @prompt_label)
      end
    end
  end
end
