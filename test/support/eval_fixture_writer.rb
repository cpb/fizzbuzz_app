module EvalFixtureWriter
  def self.append(dir, runs)
    runs.each do |run|
      append_record(dir, "runs.yml", "run", run, [ "active_job_id", "provider", "model", "started_at", "ended_at", "ruby_llm_evals_prompt_id" ])
      run.prompt_executions.each do |e|
        append_record(dir, "executions.yml", "execution", e, [ "active_job_id", "ruby_llm_evals_run_id", "ruby_llm_evals_sample_id", "message", "input", "output", "passed" ])
      end
    end
  end

  private

  def self.append_record(dir, filename, type, record, fields)
    path = Rails.root.join("evals", dir, filename)
    data = path.exist? ? YAML.safe_load(File.read(path), permitted_classes: [ Symbol, Time, ActiveSupport::TimeWithZone, ActiveSupport::TimeZone ], aliases: true) : {}

    key = "#{type}_#{SecureRandom.hex(4)}"

    # Structure with _fixture and model_class as required
    record_data = {
      "_fixture" => key,
      "model_class" => record.class.name
    }

    fields.each do |field|
      record_data[field] = record.send(field)
    end

    data[key] = record_data
    File.write(path, data.to_yaml)
  end
end
