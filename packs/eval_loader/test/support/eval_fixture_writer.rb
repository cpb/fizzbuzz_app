module EvalFixtureWriter
  PERMITTED_CLASSES = [ Symbol, Time, ActiveSupport::TimeWithZone, ActiveSupport::TimeZone ].freeze

  def self.append(dir, runs, sample_labels: {}, prompt_label: nil)
    Array(runs).each do |run|
      run_key = "runs_#{SecureRandom.hex(4)}"
      write_run(dir, run, run_key, prompt_label)
      run.prompt_executions.each { |e| write_execution(dir, e, run_key, sample_labels) }
    end
  end

  private

  def self.write_run(dir, run, run_key, prompt_label)
    append_record(dir, "runs.yml", run.class.name, run_key, {
      "active_job_id" => run.active_job_id,
      "provider" => run.provider,
      "model" => run.model,
      "started_at" => run.started_at,
      "ended_at" => run.ended_at,
      "prompt" => prompt_label || run.ruby_llm_evals_prompt_id
    })
  end

  def self.write_execution(dir, execution, run_key, sample_labels)
    append_record(dir, "executions.yml", execution.class.name, "executions_#{SecureRandom.hex(4)}", {
      "active_job_id" => execution.active_job_id,
      "run" => run_key,
      "sample" => (sample_labels[execution.ruby_llm_evals_sample_id] || execution.ruby_llm_evals_sample_id).to_s,
      "eval_type" => execution.eval_type,
      "expected_output" => execution.expected_output,
      "message" => execution.message,
      "input" => execution.input,
      "output" => execution.output,
      "passed" => execution.passed
    })
  end

  def self.append_record(dir, filename, model_class, key, record_data)
    path = Rails.root.join("evals", dir, filename)
    data = path.exist? ? YAML.safe_load(File.read(path), permitted_classes: PERMITTED_CLASSES, aliases: true) || {} : {}
    data["_fixture"] ||= { "model_class" => model_class }
    data[key] = record_data
    File.write(path, data.to_yaml)
  end
end
