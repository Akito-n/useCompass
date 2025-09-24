# frozen_string_literal: true

require 'parser/current'

module Usecompass
  class RakeAnalyzer
    def initialize(root_path, config)
      @root_path = root_path
      @config = config
    end

    def analyze
      violations = []
      rake_files.each do |file_path|
        next if excluded_rake?(file_path)
        
        violations.concat(analyze_rake_file(file_path))
      end
      violations
    end

    private

    def rake_files
      Dir.glob(File.join(@root_path, 'lib/tasks/**/*.rake'))
    end

    def excluded_rake?(file_path)
      relative_path = file_path.sub(@root_path + '/', '')
      @config.dig('exclusions', 'rake_files')&.include?(relative_path)
    end

    def excluded_task?(file_path, task_name)
      relative_path = file_path.sub(@root_path + '/', '')
      excluded_tasks = @config.dig('exclusions', 'rake_tasks') || []
      
      excluded_tasks.any? do |exclusion|
        exclusion['rake_file'] == relative_path && 
        exclusion['tasks']&.include?(task_name)
      end
    end

    def analyze_rake_file(file_path)
      violations = []
      source = File.read(file_path)
      
      begin
        ast = Parser::CurrentRuby.parse(source)
        violations.concat(check_tasks_for_usecase_calls(ast, file_path))
      rescue Parser::SyntaxError => e
        # Skip files with syntax errors
        puts "Warning: Could not parse #{file_path}: #{e.message}"
      end
      
      violations
    end

    def check_tasks_for_usecase_calls(node, file_path)
      violations = []
      return violations unless node.is_a?(Parser::AST::Node)

      case node.type
      when :send
        # rake task definition: task :task_name do |t|
        if node.children[1] == :task && node.children[2].is_a?(Parser::AST::Node)
          task_name = extract_task_name(node.children[2])
          if task_name && !excluded_task?(file_path, task_name)
            task_block = find_task_block(node)
            unless calls_usecase?(task_block)
              violations << {
                file: file_path.sub(@root_path + '/', ''),
                task: task_name,
                line: node.loc.line
              }
            end
          end
        end
      end

      # 子ノードを再帰的に検索
      node.children.each do |child|
        if child.is_a?(Parser::AST::Node)
          violations.concat(check_tasks_for_usecase_calls(child, file_path))
        end
      end

      violations
    end

    def extract_task_name(node)
      case node.type
      when :sym
        node.children[0].to_s
      when :str
        node.children[0]
      else
        nil
      end
    end

    def find_task_block(task_node)
      # task node の後にブロックがあるか確認
      task_node.children.each do |child|
        return child if child.is_a?(Parser::AST::Node) && child.type == :block
      end
      
      # ブロックが見つからない場合、親ノードから探す
      nil
    end

    def calls_usecase?(node)
      return false unless node.is_a?(Parser::AST::Node)
      
      case node.type
      when :send
        # メソッド呼び出しをチェック
        method_name = node.children[1]&.to_s
        return true if method_name&.end_with?('usecase') || method_name&.include?('Usecase')
        
        receiver = node.children[0]
        if receiver.is_a?(Parser::AST::Node) && receiver.type == :const
          const_name = extract_const_name(receiver)
          return true if const_name&.include?('Usecase')
        end
      when :lvasgn, :ivasgn
        # 変数代入の右辺をチェック
        return calls_usecase?(node.children[1])
      end
      
      # 子ノードを再帰的にチェック
      node.children.each do |child|
        return true if child.is_a?(Parser::AST::Node) && calls_usecase?(child)
      end
      
      false
    end

    def extract_const_name(const_node)
      return nil unless const_node.type == :const
      
      if const_node.children[0].nil?
        const_node.children[1].to_s
      else
        parent = extract_const_name(const_node.children[0])
        "#{parent}::#{const_node.children[1]}"
      end
    end
  end
end