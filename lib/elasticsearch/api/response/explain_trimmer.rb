module Elasticsearch
  module API
    module Response
      class ExplainTrimmer
        def initialize
        end

        def trim(tree)
          trim_node(tree)
        end

        private

          def trim_node(node)
            case
            when node.product?
              trim_product_node(node)
            when node.score?
              trim_score_node(node)
            when node.func_score?
              trim_func_score_node(node)
            when node.min?
              trim_min_score_node(node)
            else
              trim_default_node(node)
            end
          end

          def trim_score_node(node)
            case node.children.size
            when 1
              return trim_node(node.children.first)
            else
              trim_default_node(node)
            end
          end

          def trim_product_node(node)
            case node.children.size
            when 2
              constant = node.children.find { |n| n.constant? }
              if constant
                other = (node.children - [constant])[0]
                if constant.score_one? && other.score == node.score
                  return trim_node(other)
                end
              end
            end

            trim_default_node(node)
          end

          def trim_func_score_node(node)
            case node.children.size
            when 2
              boost = node.children.find { |n| n.match? || n.query_boost? }
              if boost
                other = (node.children - [boost])[0]
                if boost.score_one? && other.score == node.score
                  other = trim_node(other) if other.has_children?
                  entity = boost.field == "*" ? other : boost
                  new_node = merge_function_score_node(node, entity)
                  new_node.children = other.children
                  return trim_node(new_node)
                end
              end
            end

            trim_default_node(node)
          end

          def trim_default_node(node)
            if node.has_children?
              node.children = node.children.map(&method(:trim_node)).compact
            end
            node
          end

          # @note show only the node with a minimum score
          def trim_min_score_node(node)
            child = node.children.find {|n| n.score == node.score }
            trim_node(child)
          end

          def merge_function_score_node(current, entity)
            ExplainNode.new(
              score: current.score,
              level: current.level,
              details: current.details,
              description: Description.new(
                raw: current.description.raw,
                type: entity.type,
                operator: entity.operator,
                operation: entity.operation,
                field: entity.field,
                value: entity.value
              )
            )
          end
      end
    end
  end
end
