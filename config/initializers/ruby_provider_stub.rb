Rails.application.config.after_initialize do
  # NOTE: installed gem v0.1.0 dispatches through Prompt#execute (not Run#execute).
  # Prepend at Prompt until the local gem source (which uses Run) is released.
  # Real implementation: prepend RubyProvider::ExecutableExtension into
  # RubyLLM::Evals::Executable so the strategy applies to all includers.
  RubyLLM::Evals::Prompt.prepend(RubyProvider::ExecutableExtension)
end
