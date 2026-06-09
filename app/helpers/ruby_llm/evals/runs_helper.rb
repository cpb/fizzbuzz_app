module RubyLLM
  module Evals
    module RunsHelper
      FIZZBUZZ_CATEGORIES = %i[number fizz buzz fizzbuzz].freeze

      def fizzbuzz_run?(run)
        run.prompt_executions.any? { |e| execution_variables(e)&.key?("number") }
      end

      def execution_variables(execution)
        execution.variables.presence || execution.sample&.variables
      end

      def fizzbuzz_expected_category(number)
        n = number.to_i
        if (n % 15).zero? then :fizzbuzz
        elsif (n % 3).zero? then :fizz
        elsif (n % 5).zero? then :buzz
        else :number
        end
      end

      def fizzbuzz_predicted_category(message)
        t = message.to_s.downcase
        if t.match?(/fizzbuzz/) then :fizzbuzz
        elsif t.match?(/fizz/) then :fizz
        elsif t.match?(/buzz/) then :buzz
        else :number
        end
      end

      def fizzbuzz_grid_data(run)
        executions = run.prompt_executions.select { |e| execution_variables(e)&.key?("number") }
        by_number = executions.group_by { |e| execution_variables(e)["number"].to_i }.sort_by(&:first)

        by_number.map do |number, execs|
          expected = fizzbuzz_expected_category(number)
          exec = execs.first
          predicted = fizzbuzz_predicted_category(exec.message.to_s) if exec

          { number:, expected:, predicted:, passed: exec&.passed, exec: }
        end
      end

      def fizzbuzz_cell_style(category, entry)
        color =
          if entry[:expected] == category
            entry[:passed] ? "#282828" : "#ff3860"
          elsif !entry[:passed] && entry[:predicted] == category
            "#b3ddf2"
          else
            "#f0f0f0"
          end

        "background-color: #{color};"
      end

      def fizzbuzz_cell_title(category, entry)
        if entry[:expected] == category
          if entry[:passed]
            "✓ #{entry[:number]} → #{category} (correct)"
          else
            "✗ #{entry[:number]} expected #{category}, got \"#{entry[:exec]&.message&.strip&.truncate(40)}\""
          end
        elsif !entry[:passed] && entry[:predicted] == category
          "model predicted #{category} for #{entry[:number]} (should be #{entry[:expected]})"
        else
          "#{entry[:number]} → #{category} (not tested)"
        end
      end
    end
  end
end
