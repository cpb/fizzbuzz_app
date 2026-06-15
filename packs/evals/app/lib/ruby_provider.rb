class RubyProvider
  class CleanRoom < BasicObject
    def initialize(variables)
      @variables = variables
    end

    def variables
      @variables
    end

    def __run__(code)
      instance_eval(code)
    end
  end

  def self.call(code:, variables: {})
    CleanRoom.new(variables.with_indifferent_access).__run__(code).to_s
  end

  module ExecutableExtension
    def execute(variables: {}, files: [])
      return super unless provider == "ruby"

      result = RubyProvider.call(code: message, variables: variables)
      Struct.new(:content, :input_tokens, :output_tokens).new(result, 0, 0)
    end
  end
end
