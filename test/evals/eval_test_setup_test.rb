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
end
