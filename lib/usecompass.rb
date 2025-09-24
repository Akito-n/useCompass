# frozen_string_literal: true

require_relative "usecompass/version"
require_relative "usecompass/controller_analyzer"
require_relative "usecompass/usecase_analyzer"
require_relative "usecompass/config_loader"
require_relative "usecompass/reporter"
require_relative "usecompass/cli"

module Usecompass
  class Error < StandardError; end

  def self.check(root_path: Dir.pwd, config_path: nil)
    config_path ||= File.join(root_path, 'usecompass.yml')
    config = ConfigLoader.new(config_path).load
    
    controller_violations = ControllerAnalyzer.new(root_path, config).analyze
    usecase_violations = UsecaseAnalyzer.new(root_path, config).analyze
    
    {
      controller_violations: controller_violations,
      usecase_violations: usecase_violations
    }
  end
end