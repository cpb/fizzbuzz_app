class RubyProvider
  def self.call(code:, variables: {})
  end

  module ExecutableExtension
    def execute(variables: {}, files: [])
      return super unless provider == "ruby"

      Struct.new(:content, :input_tokens, :output_tokens).new("", 0, 0)
    end
  end
end
