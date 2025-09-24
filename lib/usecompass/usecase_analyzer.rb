# frozen_string_literal: true

module Usecompass
  class UsecaseAnalyzer
    def initialize(root_path, config)
      @root_path = root_path
      @config = config
    end

    def analyze
      violations = []
      
      usecase_files.each do |usecase_file|
        next if excluded_usecase?(usecase_file)
        
        expected_spec_file = derive_spec_path(usecase_file)
        unless File.exist?(expected_spec_file)
          violations << {
            file: usecase_file.sub(@root_path + '/', ''),
            expected_spec: expected_spec_file.sub(@root_path + '/', '')
          }
        end
      end
      
      violations
    end

    private

    def usecase_files
      # layered/usecase ディレクトリからusecaseファイルを探す
      usecase_patterns = [
        File.join(@root_path, 'layered/usecase/**/*_usecase.rb'),
        File.join(@root_path, 'app/usecases/**/*_usecase.rb'),
        File.join(@root_path, 'app/**/*_usecase.rb')
      ]
      
      files = []
      usecase_patterns.each do |pattern|
        files.concat(Dir.glob(pattern))
      end
      
      files.uniq
    end

    def excluded_usecase?(file_path)
      relative_path = file_path.sub(@root_path + '/', '')
      @config.dig('exclusions', 'usecase_specs')&.include?(relative_path)
    end

    def derive_spec_path(usecase_file)
      relative_path = usecase_file.sub(@root_path + '/', '')
      
      # Check for custom mapping first
      custom_mapping = find_custom_usecase_mapping(relative_path)
      if custom_mapping
        return File.join(@root_path, custom_mapping)
      end
      
      # Default mapping logic
      # layered/usecase/xxx/yyy_usecase.rb -> spec/layered/usecase/xxx/yyy_usecase_spec.rb
      if relative_path.start_with?('layered/')
        spec_path = relative_path.sub('layered/', 'spec/layered/')
      # app/usecases/xxx/yyy_usecase.rb -> spec/usecases/xxx/yyy_usecase_spec.rb  
      elsif relative_path.start_with?('app/')
        spec_path = relative_path.sub('app/', 'spec/')
      else
        # その他の場合はspec/ディレクトリに置く
        spec_path = "spec/#{relative_path}"
      end
      
      # _usecase.rb -> _usecase_spec.rb に変換
      spec_path = spec_path.sub('_usecase.rb', '_usecase_spec.rb')
      
      File.join(@root_path, spec_path)
    end

    def find_custom_usecase_mapping(usecase_file_relative_path)
      custom_mappings = @config.dig('custom_mappings', 'usecases') || []
      
      custom_mappings.each do |mapping|
        if mapping['usecase_file'] == usecase_file_relative_path
          return mapping['spec_file']
        end
      end
      
      nil
    end
  end
end