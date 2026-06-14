require "support/eval_fixture_writer"

module EvalTestSetup
  extend ActiveSupport::Concern

  included do
    self.fixture_paths = [ Rails.root.join("evals") ]
    self.fixture_table_names = []

    fixtures :"runs", :"prompt_executions"

    parallelize(workers: 1)
  end

  def load_fixtures(config)
    # Both eval and standard fixture classes populate @@all_cached_fixtures
    # with entries for the same physical tables but under DIFFERENT set names
    # ("fizzbuzz/prompts" vs "ruby_llm/evals/prompts"). Neither side clears the
    # other's cache entries on a class transition, so the opposing set can
    # remain cached pointing at the wrong DB state. Clearing the whole cache
    # here (only called on a real class transition, not on same-class cache
    # hits in @@already_loaded_fixtures) gives create_fixtures a clean slate so
    # it reloads from disk and issues the correct DELETEs before inserting eval
    # data.
    ActiveRecord::FixtureSet.reset_cache
    super
  end

  def with_eval_cassette(name)
    use_cassette(name, caller_depth: 2, record: ENV["RECORD_EVALS"] ? :all : :new_episodes) do |cassette|
      yield
      if cassette.new_recorded_interactions.any?
        EvalFixtureWriter.append(@eval_dir, @runs, sample_labels: @sample_labels, prompt_label: @prompt_label)
      end
    end
  end
end
