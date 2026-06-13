require "yaml"

module EvalLoader
  def self.seed_dir(dir)
    base = Rails.root.join("evals", dir)
    prompts_file = base.join("prompts.yml")
    samples_file = base.join("samples.yml")

    return unless prompts_file.exist? && samples_file.exist?

    prompts = YAML.load_file(prompts_file)
    samples = YAML.load_file(samples_file)

    prompt_model_class = prompts["_fixture"]["model_class"].constantize
    prompt_records = {}
    prompts.except("_fixture").each do |label, attrs|
      prompt_records[label] = prompt_model_class.find_or_create_by!(slug: attrs["slug"]) do |p|
        p.assign_attributes(attrs)
      end
    end

    samples.except("_fixture").each do |label, attrs|
      prompt = prompt_records[attrs["prompt"]]

      sample = prompt.samples.find_or_initialize_by(variables: attrs["variables"])
      sample.assign_attributes(attrs.except("prompt"))
      sample.prompt = prompt
      sample.save!
    end
  end
end
