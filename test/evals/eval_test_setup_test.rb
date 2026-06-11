require "test_helper"
require "support/eval_test_setup"

class EvalTestSetupTest < ActiveSupport::TestCase
  test "with_eval_cassette does not write fixture YAML during cassette playback" do
    output_dir = Dir.mktmpdir

    klass = Class.new(ActiveSupport::TestCase) do
      include EvalTestSetup
      fixtures :"fizzbuzz/prompts", :"fizzbuzz/samples"
    end

    instance = klass.new("playback_test")
    instance.instance_variable_set(:@runs, [])
    instance.instance_variable_set(:@sample_labels, {})
    instance.instance_variable_set(:@eval_dir, output_dir)
    instance.instance_variable_set(:@prompt_label, "fizzbuzz_basic")

    instance.with_eval_cassette("fizzbuzz_basic_15") { }

    assert Dir.glob(File.join(output_dir, "*.yml")).empty?,
      "No YAML files should be written during cassette playback"
  ensure
    FileUtils.rm_rf(output_dir)
  end
end
