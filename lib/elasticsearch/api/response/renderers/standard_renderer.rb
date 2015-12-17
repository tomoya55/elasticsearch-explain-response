require "elasticsearch/api/response/renderers/base_renderer"

module Elasticsearch
  module API
    module Response
      module Renderers

        class StandardRenderer < BaseRenderer

          def render(tree)
            @buffer = []
            recursive_render(tree)
            @buffer.join("\n")
          end

          private

            def recursive_render(node)
              return if node.level > @max
              render_result(node) if node.details.any?
              node.children.each do |child|
                recursive_render(child)
              end
            end

            def render_result(node)
              @buffer << " " * node.level * 2 + [render_score(node.score), "=", render_details(node)].flatten.join(" ")
            end

            def render_details(node)
              if node.has_children?
                node.children.map(&method(:render_node)).compact.join(" #{node.operator} ")
              else
                render_node(node)
              end
            end
        end
      end
    end
  end
end
