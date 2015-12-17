require "elasticsearch/api/response/renderers/base_renderer"

module Elasticsearch
  module API
    module Response
      module Renderers
        class InlineRenderer < BaseRenderer

          def render(tree)
            [render_score(tree.score), "=", recursive_render_details(tree)].flatten.join(" ")
          end

          private

            def recursive_render_details(node)
              details = node.children.map do |child|
                if child.children.any? && child.level <= @max
                  recursive_render_details(child)
                else
                  if !child.match_all?
                    render_node(child)
                  end
                end
              end.compact

              if details.size > 1
                wrap_paren(details.join(" #{node.operator} "))
              else
                details[0]
              end
            end
        end
      end
    end
  end
end
