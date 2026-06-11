require "test_helper"
require "support/eval_test_setup"

class EvalTestSetupTest < ActiveSupport::TestCase
  include EvalTestSetup
  fixtures :"fizzbuzz/prompts", :"fizzbuzz/samples"

  setup do
    @runs = []
    @sample_labels = {}
    @eval_dir = Dir.mktmpdir
    @prompt_label = "fizzbuzz_basic"
  end

  teardown do
    FileUtils.rm_rf(@eval_dir)
  end

  test "with_eval_cassette does not write fixture YAML during cassette playback" do
    with_eval_cassette("fizzbuzz_basic_15") { }
    assert Dir.glob(File.join(@eval_dir, "*.yml")).empty?,
      "No YAML files should be written during cassette playback"
  end

  test "with_eval_cassette writes fixture YAML when cassette records new interactions" do
    appended = false

    original_append = EvalFixtureWriter.method(:append)
    original_use_cassette = VCR.method(:use_cassette)

    EvalFixtureWriter.define_singleton_method(:append) { |*| appended = true }
    VCR.define_singleton_method(:use_cassette) do |_name, **_opts, &blk|
      stub_cassette = Struct.new(:new_recorded_interactions).new([ "fake_interaction" ])
      blk.call(stub_cassette)
    end

    begin
      with_eval_cassette("nonexistent") { }
    ensure
      EvalFixtureWriter.define_singleton_method(:append, &original_append)
      VCR.define_singleton_method(:use_cassette, &original_use_cassette)
    end

    assert appended, "EvalFixtureWriter.append should be called when cassette records new interactions"
  end
end
