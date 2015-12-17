module Elasticsearch
  module API
    module Response
      module Renderers
        class HashRenderer

          def render(tree)
            recursive_render(tree)
          end

          def recursive_render(node)
            format_node(node) if node.details.any?
          end

          private

            def format_node(node)
              node.as_json.tap do |hash|
                if node.has_children?
                  children = format_children(node, hash)
                  hash[:children] = children if children.any?
                end
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
        end
      end
    end
  end
end
