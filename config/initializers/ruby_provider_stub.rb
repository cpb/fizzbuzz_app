# Stub: intercept ruby provider execution so tests reach an assertion
# failure rather than a ModelNotFoundError. The real implementation
# belongs in the ruby_llm-evals gem extension or a concern.
#
# Returns a fake response with empty content so PromptExecution#execute
# saves message = "" and the assertion assert_equal "6", execution.message
# fails with the expected vs actual value shown clearly.
Rails.application.config.after_initialize do
  RubyLLM::Evals::Prompt.prepend(Module.new do
    def execute(variables: {}, files: [])
      return super unless provider == "ruby"

      Struct.new(:content, :input_tokens, :output_tokens).new("", 0, 0)
    end
  end)
end
