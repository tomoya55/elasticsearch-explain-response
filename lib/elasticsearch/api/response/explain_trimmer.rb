module Elasticsearch
  module API
    module Response
      class ExplainTrimmer
        def initialize
        end

        def trim(tree)
          recursive_trim(tree)
        end

        def recursive_trim(node)
          trim_node(node) if node.details.any?
        end

        private

        def trim_node(node)
          case
          when node.func_score?
            trim_func_score_node(node)
          when node.min?
            trim_min_score_node(node)
          else
            trim_default_node(node)
          end
        end

        def trim_func_score_node(node)
          case node.children.size
          when 2
            match = node.children.find(&:match?)
            if match
              other = (node.children - [match])[0]
              if match.score_one? && other.score == node.score
                entity = match.field == "*" ? other : match
                return merge_function_score_node(node, entity)
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
