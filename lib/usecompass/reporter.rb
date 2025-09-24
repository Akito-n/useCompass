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
      rake_violations = violations[:rake_violations] || []
      rake_spec_violations = violations[:rake_spec_violations] || []
      
      # 実行されたチェックの種類を判定
      controller_check_run = !violations[:controller_violations].nil?
      usecase_check_run = !violations[:usecase_violations].nil?
      rake_check_run = !violations[:rake_violations].nil?
      rake_spec_check_run = !violations[:rake_spec_violations].nil?
      
      all_empty = controller_violations.empty? && usecase_violations.empty? && 
                  rake_violations.empty? && rake_spec_violations.empty?

      if all_empty
        # Success message based on which checks were run
        if controller_check_run && usecase_check_run && rake_check_run && rake_spec_check_run
          @output.puts Rainbow("✓ All checks passed!").green
        elsif controller_check_run && !usecase_check_run && !rake_check_run && !rake_spec_check_run
          @output.puts Rainbow("✓ Controller checks passed!").green
        elsif !controller_check_run && usecase_check_run && !rake_check_run && !rake_spec_check_run
          @output.puts Rainbow("✓ Usecase spec checks passed!").green
        elsif !controller_check_run && !usecase_check_run && rake_check_run && !rake_spec_check_run
          @output.puts Rainbow("✓ Rake usecase checks passed!").green
        elsif !controller_check_run && !usecase_check_run && !rake_check_run && rake_spec_check_run
          @output.puts Rainbow("✓ Rake spec checks passed!").green
        else
          @output.puts Rainbow("✓ Selected checks passed!").green
        end
        return
      end

      # Display violations
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

      unless rake_violations.empty?
        @output.puts Rainbow("\n⚠ Rake files not calling usecases:").yellow.bold
        rake_violations.each do |violation|
          @output.puts "  #{violation[:file]}:#{violation[:line]} - #{violation[:task]}"
        end
      end

      unless rake_spec_violations.empty?
        @output.puts Rainbow("\n⚠ Rake files without specs:").yellow.bold
        rake_spec_violations.each do |violation|
          @output.puts "  #{violation[:file]} - #{violation[:expected_spec]}"
        end
      end

      @output.puts ""
      
      # Summary message
      total_violations = controller_violations.size + usecase_violations.size + 
                        rake_violations.size + rake_spec_violations.size
      
      if controller_check_run && usecase_check_run && rake_check_run && rake_spec_check_run
        @output.puts Rainbow("Found #{total_violations} violations").red
      else
        # Show specific violation counts for partial checks
        if controller_check_run && controller_violations.any?
          @output.puts Rainbow("Found #{controller_violations.size} controller violations").red
        elsif usecase_check_run && usecase_violations.any?
          @output.puts Rainbow("Found #{usecase_violations.size} usecase spec violations").red  
        elsif rake_check_run && rake_violations.any?
          @output.puts Rainbow("Found #{rake_violations.size} rake usecase violations").red
        elsif rake_spec_check_run && rake_spec_violations.any?
          @output.puts Rainbow("Found #{rake_spec_violations.size} rake spec violations").red
        else
          @output.puts Rainbow("Found #{total_violations} violations").red
        end
      end
    end
  end
end