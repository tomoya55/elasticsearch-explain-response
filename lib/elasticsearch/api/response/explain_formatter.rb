module Elasticsearch
  module API
    module Response
      class ExplainFormatter
        attr_reader :conditions

        def initialize(options = {})
          @conditions = [*options[:conditions]]
        end

        def format(tree)
          recursive_format(tree)
        end

        def recursive_format(node)
          format_node(node) if node.details.any?
        end

        private

        def format_node(node)
          case
          when node.func_score?
            format_func_score_node(node)
          when node.min?
            format_min_score_node(node)
          when node.score_one?
            nil
          else
            format_default_node(node)
          end
        end

        def format_children(node, hash)
          node.children.map(&method(:format_node)).compact.tap do |children|
            remove_dup(children, hash)
          end
        end

        def remove_dup(collection, target)
          collection.delete_if {|elm| elm == target }
        end

        def format_default_node(node)
          node.as_json.tap do |hash|
            if node.has_children?
              children = format_children(node, hash)
              hash[:children] = children if children.any?
            end
          end
        end

        # @note simplify the func score function with match & boost
        def format_func_score_node(node)
          case node.children.size
          when 2
            match = node.children.find(&:match?)
            boost = node.children.find(&:boost?)
            if match && boost
              return { score: node.score,
                type:  node.type,
                operation: node.operation,
                field: node.children[0].field,
                value: node.children[0].value,
               }
            end

            boost = node.children.find do |n|
              n.score_one? && (n.query_boost? || n.match?)
            end
            if boost
              other = node.children.find { |e| e != boost }
              return format_node(other)
            end
          end

          format_default_node(node)
        end

        # @note show only the node with a minimum score
        def format_min_score_node(node)
          child = node.children.find {|n| n.score == node.score }
          format_node(child)
        end
      end
    end
  end
end
