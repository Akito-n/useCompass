# frozen_string_literal: true

require 'yaml'

module Usecompass
  class ConfigLoader
    def initialize(config_path)
      @config_path = config_path
    end

    def load
      return default_config unless File.exist?(@config_path)

      config = YAML.load_file(@config_path)
      deep_merge(default_config, config)
    end

    private

    def default_config
      {
        'exclusions' => {
          'controllers' => [],
          'controller_actions' => [],
          'usecase_specs' => []
        }
      }
    end

    def deep_merge(hash1, hash2)
      result = hash1.dup
      hash2.each do |key, value|
        if result[key].is_a?(Hash) && value.is_a?(Hash)
          result[key] = deep_merge(result[key], value)
        else
          result[key] = value
        end
      end
      result
    end
  end
end