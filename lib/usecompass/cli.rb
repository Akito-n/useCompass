# frozen_string_literal: true

require 'optparse'

module Usecompass
  class CLI
    def initialize(args = ARGV)
      @args = args
      @options = {}
    end

    def run
      # サブコマンドをチェック
      subcommand = @args.first
      
      # オプション（-で始まる）ではなく、明確なサブコマンドの場合のみshiftする
      if subcommand && !subcommand.start_with?('-')
        case subcommand
        when 'init'
          @args.shift
          run_init
        when 'check'
          @args.shift
          run_check
        else
          puts "Unknown command: #{subcommand}"
          puts "Available commands: init, check (default)"
          exit(1)
        end
      else
        # サブコマンドがない場合はデフォルトでcheckを実行
        run_check
      end
    end

    private

    def run_init
      parse_init_options
      
      root_path = @options[:root_path] || Dir.pwd
      config_path = File.join(root_path, 'usecompass.yml')
      
      if File.exist?(config_path) && !@options[:force]
        print "Configuration file already exists at #{config_path}. Overwrite? [y/N]: "
        response = $stdin.gets.chomp.downcase
        unless response == 'y' || response == 'yes'
          puts "Aborted."
          exit(0)
        end
      end
      
      create_config_file(config_path)
      puts "Created configuration file: #{config_path}"
    end

    def run_check
      parse_check_options

      violations = Usecompass.check(
        root_path: @options[:root_path] || Dir.pwd,
        config_path: @options[:config_path],
        controllers_only: @options[:controllers_only],
        specs_only: @options[:specs_only],
        rakes_only: @options[:rakes_only]
      )

      reporter = Reporter.new(
        format: @options[:format] || :console,
        output: @options[:output]
      )

      reporter.report(violations)
      
      # 違反がある場合は終了コード1で終了
      controller_count = violations[:controller_violations]&.size || 0
      usecase_count = violations[:usecase_violations]&.size || 0
      rake_count = violations[:rake_violations]&.size || 0
      rake_spec_count = violations[:rake_spec_violations]&.size || 0
      exit(1) if controller_count > 0 || usecase_count > 0 || rake_count > 0 || rake_spec_count > 0
    end

    def parse_init_options
      parser = OptionParser.new do |opts|
        opts.banner = "Usage: usecompass init [options]"
        
        opts.on("-r", "--root PATH", "Root path of the project") do |path|
          @options[:root_path] = path
        end
        
        opts.on("-f", "--force", "Force overwrite existing config file") do
          @options[:force] = true
        end
        
        opts.on("-h", "--help", "Show this message") do
          puts opts
          exit
        end
      end

      parser.parse!(@args)
    rescue OptionParser::InvalidOption => e
      puts e.message
      puts parser
      exit(1)
    end

    def parse_check_options
      parser = OptionParser.new do |opts|
        opts.banner = "Usage: usecompass [check] [options]"
        
        opts.on("-r", "--root PATH", "Root path of the project") do |path|
          @options[:root_path] = path
        end
        
        opts.on("-c", "--config PATH", "Config file path") do |path|
          @options[:config_path] = path
        end
        
        opts.on("-f", "--format FORMAT", "Output format (console)") do |format|
          @options[:format] = format.to_sym
        end
        
        opts.on("-o", "--output FILE", "Output file") do |file|
          @options[:output] = File.open(file, 'w')
        end
        
        opts.on("-C", "--controllers-only", "Check controllers only") do
          @options[:controllers_only] = true
        end
        
        opts.on("-S", "--specs-only", "Check usecase specs only") do
          @options[:specs_only] = true
        end
        
        opts.on("-R", "--rakes-only", "Check rake files only") do
          @options[:rakes_only] = true
        end
        
        opts.on("-h", "--help", "Show this message") do
          puts opts
          exit
        end
        
        opts.on("-v", "--version", "Show version") do
          puts Usecompass::VERSION
          exit
        end
      end

      parser.parse!(@args)
    rescue OptionParser::InvalidOption => e
      puts e.message
      puts parser
      exit(1)
    end

    def create_config_file(config_path)
      config_content = <<~YAML
        # Configuration file for usecompass
        # https://github.com/Akito-n/useCompass

        exclusions:
          controllers:
            # Controllers that don't need to call usecases
            - "app/controllers/application_controller.rb"
            # - "app/controllers/admin/health_check_controller.rb"
          
          controller_actions:
            # Specific controller actions that don't need to call usecases
            # - controller: "app/controllers/admin/dashboard_controller.rb"
            #   actions: ["index", "show"]
          
          usecase_specs:
            # Usecases that don't need specs (e.g., legacy code)
            # - "layered/usecase/legacy/migration_usecase.rb"
          
          rake_specs:
            # Rake files that don't need specs
            # - "lib/tasks/legacy/old_task.rake"

        # Custom spec file mappings for non-standard naming
        custom_mappings:
          rakes:
            # Map rake files to their corresponding spec files when naming doesn't follow convention
            # - rake_file: "lib/tasks/hoge_one.rake"
            #   spec_file: "spec/lib/tasks/hoge_one_1_spec.rb"
          
          usecases:
            # Map usecase files to their corresponding spec files when naming doesn't follow convention
            # - usecase_file: "layered/usecase/some_usecase.rb"
            #   spec_file: "spec/layered/usecase/some_custom_spec.rb"
      YAML

      File.write(config_path, config_content)
    end
  end
end