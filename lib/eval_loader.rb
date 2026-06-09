require "yaml"

module EvalLoader
  def self.seed_dir(dir)
    base = Rails.root.join("evals", dir)
    prompts_file = base.join("prompts.yml")
    samples_file = base.join("samples.yml")

    return unless prompts_file.exist? && samples_file.exist?

    prompts = YAML.load_file(prompts_file)
    samples = YAML.load_file(samples_file)

    # Load prompts idempotently
    prompt_records = prompts.map do |label, attrs|
      model_class = attrs["model_class"].constantize
      model_class.find_or_create_by!(slug: attrs["slug"]) do |p|
        p.assign_attributes(attrs.reject { |k| [ "_fixture", "model_class" ].include?(k) })
      end
    end

    # Load samples idempotently
    samples.each do |label, attrs|
      model_class = attrs["model_class"].constantize
      prompt = prompt_records.find { |p| p.slug == attrs["prompt_slug"] }

      # Idempotent lookup for samples
      sample = prompt.samples.find_or_initialize_by(
        variables: attrs["variables"]
      )

      sample.assign_attributes(attrs.reject { |k| [ "_fixture", "model_class", "prompt_slug" ].include?(k) })
      sample.prompt = prompt
      sample.save!
    end
  end
end
