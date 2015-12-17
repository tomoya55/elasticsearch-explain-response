require "elasticsearch/api/response/color_helper"

module Elasticsearch
  module API
    module Response
      class ExplainRenderer
        include ColorHelper

        def initialize(options = {})
          disable_colorization if options[:colorize] == false
          @max = options[:max] || 3
          @plain_score = options[:plain_score] == true
          @show_values = options[:show_values] == true
        end

        def render(tree)
          @buffer = []
          recursive_render(tree)
          @buffer.join("\n")
        end

        def render_in_line(tree)
          [render_score(tree.score), "=", recursive_render_details(tree)].flatten.join(" ")
        end

        def recursive_render(node)
          return if node.level > @max
          render_result(node) if node.details.any?
          node.children.each do |child|
            recursive_render(child)
          end
        end

        private

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
