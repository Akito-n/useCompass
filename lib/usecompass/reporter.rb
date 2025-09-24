# frozen_string_literal: true

require 'rainbow'

module Usecompass
  class Reporter
    def initialize(format: :console, output: nil)
      @format = format
      @output = output || $stdout
    end

    def report(violations)
      case @format
      when :console
        console_report(violations)
      else
        raise ArgumentError, "Unsupported format: #{@format}"
      end
    end

    private

    def console_report(violations)
      controller_violations = violations[:controller_violations] || []
      usecase_violations = violations[:usecase_violations] || []

      if controller_violations.empty? && usecase_violations.empty?
        @output.puts Rainbow("✓ All checks passed!").green
        return
      end

      unless controller_violations.empty?
        @output.puts Rainbow("\n⚠ Controllers not calling usecases:").yellow.bold
        controller_violations.each do |violation|
          @output.puts "  #{violation[:file]}:#{violation[:line]} - #{violation[:action]}"
        end
      end

      unless usecase_violations.empty?
        @output.puts Rainbow("\n⚠ Usecases without specs:").yellow.bold
        usecase_violations.each do |violation|
          @output.puts "  #{violation[:file]} - #{violation[:expected_spec]}"
        end
      end

      @output.puts ""
      @output.puts Rainbow("Found #{controller_violations.size + usecase_violations.size} violations").red
    end
  end
end