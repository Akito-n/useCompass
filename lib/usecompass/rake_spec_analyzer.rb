# frozen_string_literal: true

module Usecompass
  class RakeSpecAnalyzer
    def initialize(root_path, config)
      @root_path = root_path
      @config = config
    end

    def analyze
      violations = []
      
      rake_files.each do |rake_file|
        next if excluded_rake_spec?(rake_file)
        
        expected_spec_file = derive_spec_path(rake_file)
        unless File.exist?(expected_spec_file)
          violations << {
            file: rake_file.sub(@root_path + '/', ''),
            expected_spec: expected_spec_file.sub(@root_path + '/', '')
          }
        end
      end
      
      violations
    end

    private

    def rake_files
      Dir.glob(File.join(@root_path, 'lib/tasks/**/*.rake'))
    end

    def excluded_rake_spec?(file_path)
      relative_path = file_path.sub(@root_path + '/', '')
      @config.dig('exclusions', 'rake_specs')&.include?(relative_path)
    end

    def derive_spec_path(rake_file)
      relative_path = rake_file.sub(@root_path + '/', '')
      
      # lib/tasks/xxx/yyy.rake -> spec/lib/tasks/xxx/yyy_spec.rb
      spec_path = relative_path.sub('lib/', 'spec/lib/')
      spec_path = spec_path.sub('.rake', '_spec.rb')
      
      File.join(@root_path, spec_path)
    end
  end
end