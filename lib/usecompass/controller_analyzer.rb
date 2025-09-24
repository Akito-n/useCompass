# frozen_string_literal: true

require 'parser/current'

module Usecompass
  class ControllerAnalyzer
    def initialize(root_path, config)
      @root_path = root_path
      @config = config
    end

    def analyze
      violations = []
      controller_files.each do |file_path|
        next if excluded_controller?(file_path)
        
        violations.concat(analyze_controller_file(file_path))
      end
      violations
    end

    private

    def controller_files
      Dir.glob(File.join(@root_path, 'app/controllers/**/*_controller.rb'))
    end

    def excluded_controller?(file_path)
      relative_path = file_path.sub(@root_path + '/', '')
      @config.dig('exclusions', 'controllers')&.include?(relative_path)
    end

    def excluded_action?(file_path, action_name)
      relative_path = file_path.sub(@root_path + '/', '')
      excluded_actions = @config.dig('exclusions', 'controller_actions') || []
      
      excluded_actions.any? do |exclusion|
        exclusion['controller'] == relative_path && 
        exclusion['actions']&.include?(action_name)
      end
    end

    def analyze_controller_file(file_path)
      violations = []
      source = File.read(file_path)
      
      begin
        ast = Parser::CurrentRuby.parse(source)
        violations.concat(check_actions_for_usecase_calls(ast, file_path))
      rescue Parser::SyntaxError => e
        # Skip files with syntax errors
        puts "Warning: Could not parse #{file_path}: #{e.message}"
      end
      
      violations
    end

    def check_actions_for_usecase_calls(node, file_path, current_line = 1)
      violations = []
      return violations unless node.is_a?(Parser::AST::Node)

      case node.type
      when :class
        # クラス定義内を検索
        if controller_class?(node)
          violations.concat(find_action_methods(node, file_path))
        end
      end

      # 子ノードを再帰的に検索
      node.children.each do |child|
        if child.is_a?(Parser::AST::Node)
          violations.concat(check_actions_for_usecase_calls(child, file_path, current_line))
        end
      end

      violations
    end

    def controller_class?(node)
      return false unless node.type == :class
      
      class_name = extract_class_name(node)
      class_name&.end_with?('Controller')
    end

    def extract_class_name(node)
      return nil unless node.type == :class
      
      name_node = node.children[0]
      case name_node.type
      when :const
        name_node.children[1].to_s
      when :casgn
        name_node.children[1].to_s
      else
        nil
      end
    end

    def find_action_methods(class_node, file_path)
      violations = []
      
      class_node.children.each do |child|
        next unless child.is_a?(Parser::AST::Node)
        
        if child.type == :def
          method_name = child.children[0].to_s
          next unless looks_like_action?(method_name)
          next if excluded_action?(file_path, method_name)
          
          method_body = child.children[2]
          unless calls_usecase?(method_body)
            violations << {
              file: file_path.sub(@root_path + '/', ''),
              action: method_name,
              line: child.loc.line
            }
          end
        end
      end
      
      violations
    end

    def looks_like_action?(method_name)
      # 一般的なRailsアクション名パターンをチェック
      common_actions = %w[index show new create edit update destroy]
      return true if common_actions.include?(method_name)
      
      # プライベートメソッドやヘルパーメソッドは除外
      !method_name.start_with?('_') && !method_name.end_with?('?')
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