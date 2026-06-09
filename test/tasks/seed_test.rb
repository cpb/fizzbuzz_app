require "test_helper"

class SeedTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  def before_setup
    WorkbookSession.delete_all
    BiasedThought.delete_all
    super
  end

  def after_teardown
    super
    WorkbookSession.delete_all
    BiasedThought.delete_all
  end

  test "db:seed creates an auth-PR WorkbookSession with all required fields" do
    load Rails.root.join("db/seeds.rb")

    session = WorkbookSession.find_by("situation_description LIKE ?", "%auth%")
    assert_not_nil session, "Expected a WorkbookSession with 'auth' in situation_description to exist after seeding"

    assert_not_nil session.suds_initial, "Expected suds_initial to be set"
    assert_not_nil session.suds_post_tipp, "Expected suds_post_tipp to be set"
    assert_not_nil session.suds_post_restructuring, "Expected suds_post_restructuring to be set"

    assert_not_nil session.tipp_strategy, "Expected tipp_strategy to be set"

    assert session.biased_thoughts.any?, "Expected at least one BiasedThought associated with the session"
    session.biased_thoughts.each do |bt|
      assert_not_nil bt.pre_believability, "Expected pre_believability on BiasedThought"
      assert_not_nil bt.post_believability, "Expected post_believability on BiasedThought"
    end

    assert_not_nil session.primary_thought_id, "Expected primary_thought_id to be set"

    assert_not_nil session.rational_response, "Expected rational_response to be set"
    assert_not_nil session.rational_believability, "Expected rational_believability to be set"

    assert_not_nil session.dear_plan, "Expected dear_plan to be set"
  end
end
