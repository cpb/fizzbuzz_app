class RubyProvider
  def self.call(code:, variables: {})
  end

  # Prepended into RubyLLM::Evals::Executable (via after_initialize) so that
  # Run#execute — which PromptExecution delegates to — dispatches to RubyProvider
  # instead of calling RubyLLM.chat when provider == "ruby".
  module ExecutableExtension
    def execute(variables: {}, files: [])
      return super unless provider == "ruby"

      Struct.new(:content, :input_tokens, :output_tokens).new("", 0, 0)
    end
  end
end
