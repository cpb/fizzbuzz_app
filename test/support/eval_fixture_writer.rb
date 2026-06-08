module EvalFixtureWriter
  def self.append(dir, runs)
    Array(runs).each do |run|
      append_record(dir, "runs.yml", run, [ "active_job_id", "provider", "model", "started_at", "ended_at", "ruby_llm_evals_prompt_id" ])
      run.prompt_executions.each do |e|
        append_record(dir, "executions.yml", e, [ "active_job_id", "ruby_llm_evals_run_id", "ruby_llm_evals_sample_id", "message", "input", "output", "passed" ])
      end
    end
  end

  private

  def self.append_record(dir, filename, record, fields)
    path = Rails.root.join("evals", dir, filename)
    data = path.exist? ? YAML.safe_load(File.read(path), permitted_classes: [ Symbol, Time, ActiveSupport::TimeWithZone, ActiveSupport::TimeZone ], aliases: true) || {} : {}

    data["_fixture"] ||= { "model_class" => record.class.name }

    key = "#{filename.delete_suffix('.yml')}_#{SecureRandom.hex(4)}"
    record_data = {}
    fields.each { |f| record_data[f] = record.send(f) }
    data[key] = record_data

    File.write(path, data.to_yaml)
  end
end
