# frozen_string_literal: true

require_relative "usecompass/version"
require_relative "usecompass/controller_analyzer"
require_relative "usecompass/usecase_analyzer"
require_relative "usecompass/rake_analyzer"
require_relative "usecompass/rake_spec_analyzer"
require_relative "usecompass/config_loader"
require_relative "usecompass/reporter"
require_relative "usecompass/cli"

module Usecompass
  class Error < StandardError; end

  def self.check(root_path: Dir.pwd, config_path: nil, controllers_only: false, specs_only: false, rakes_only: false)
    config_path ||= File.join(root_path, 'usecompass.yml')
    config = ConfigLoader.new(config_path).load
    
    controller_violations = nil
    usecase_violations = nil
    rake_violations = nil
    rake_spec_violations = nil
    
    # Determine which checks to run based on options
    has_specific_options = controllers_only || specs_only || rakes_only
    
    if has_specific_options
      # Run specific checks based on options
      if controllers_only
        controller_violations = ControllerAnalyzer.new(root_path, config).analyze
      end
      
      if specs_only && !rakes_only
        # -S only: check usecase specs
        usecase_violations = UsecaseAnalyzer.new(root_path, config).analyze
      elsif rakes_only && !specs_only
        # -R only: check rake usecase calls
        rake_violations = RakeAnalyzer.new(root_path, config).analyze
      elsif rakes_only && specs_only
        # -R -S: check rake specs
        rake_spec_violations = RakeSpecAnalyzer.new(root_path, config).analyze
      end
    else
      # Run all checks by default
      controller_violations = ControllerAnalyzer.new(root_path, config).analyze
      usecase_violations = UsecaseAnalyzer.new(root_path, config).analyze
      rake_violations = RakeAnalyzer.new(root_path, config).analyze
      rake_spec_violations = RakeSpecAnalyzer.new(root_path, config).analyze
    end
    
    {
      controller_violations: controller_violations,
      usecase_violations: usecase_violations,
      rake_violations: rake_violations,
      rake_spec_violations: rake_spec_violations
    }
  end
end