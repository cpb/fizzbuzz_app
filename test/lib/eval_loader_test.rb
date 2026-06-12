require "test_helper"

class EvalLoaderTest < ActiveSupport::TestCase
  # Workaround for issue #122: YAML.load_file returns entries without model_class
  # because the _fixture block is not merged into individual entries by YAML.load_file.
  # We create a temporary evals/<subdir> inside Rails.root with fixed YAML files
  # (model_class injected, _fixture header removed) and call EvalLoader.seed_dir
  # with that subdir, so the real EvalLoader.seed_dir runs against properly-formed
  # YAML while isolating the prompt_slug bug (issue #132) specifically.
  def with_issue_122_fixed_evals(dir)
    base = Rails.root.join("evals", dir)

    prompts_raw = YAML.load_file(base.join("prompts.yml"))
    prompt_model = prompts_raw["_fixture"]["model_class"]
    prompts_fixed = prompts_raw.reject { |k, _v| k == "_fixture" }
                               .transform_values { |attrs| attrs.merge("model_class" => prompt_model) }

    samples_raw = YAML.load_file(base.join("samples.yml"))
    sample_model = samples_raw["_fixture"]["model_class"]
    samples_fixed = samples_raw.reject { |k, _v| k == "_fixture" }
                               .transform_values { |attrs| attrs.merge("model_class" => sample_model) }

    tmp_subdir = "#{dir}_test_tmp_#{SecureRandom.hex(4)}"
    tmp_base = Rails.root.join("evals", tmp_subdir)
    FileUtils.mkdir_p(tmp_base)
    File.write(tmp_base.join("prompts.yml"), prompts_fixed.to_yaml)
    File.write(tmp_base.join("samples.yml"), samples_fixed.to_yaml)

    yield tmp_subdir
  ensure
    FileUtils.rm_rf(tmp_base) if tmp_base
  end

  test "seed_dir loads all fizzbuzz samples with a non-nil prompt association" do
    seed_error = nil
    with_issue_122_fixed_evals("fizzbuzz") do |tmp_dir|
      begin
        EvalLoader.seed_dir(tmp_dir)
      rescue => e
        seed_error = e
      end
    end

    assert_nil seed_error,
      "EvalLoader.seed_dir raised #{seed_error.class}: #{seed_error&.message} — " \
      "samples.yml uses 'prompt:' key but seed_dir looks up 'prompt_slug:' (always nil)"

    samples = RubyLLM::Evals::Sample.all.to_a

    assert samples.count > 0,
      "Expected EvalLoader.seed_dir('fizzbuzz') to load samples, but found none"

    samples_missing_prompt = samples.reject { |s| s.prompt.present? }
    assert samples_missing_prompt.empty?,
      "Expected every sample to have a prompt, but #{samples_missing_prompt.count} sample(s) had nil prompt"
  end
end
