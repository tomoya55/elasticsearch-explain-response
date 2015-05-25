require "elasticsearch/api/response/color_helper"

module Elasticsearch
  module API
    module Response
      class ExplainRenderer
        include ColorHelper

        def initialize(options = {})
          disable_colorization if options[:colorize] == false
          @max = options[:max] || 3
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

        def render_score(score)
          ansi(score.round(2).to_s, :magenta, :bright)
        end

        def render_details(node)
          node.children.map do |child|
            render_node(child)
          end.compact.join(" #{node.operator} ")
        end

        def recursive_render_details(node)
          node.children.map do |child|
            if can_render_details?(child)
              wrap_paren(recursive_render_details(child))
            else
              render_node(child)
            end
          end.compact.join(" #{node.operator} ")
        end

        def can_render_details?(node)
          node.children.any? && node.level <= @max && node.type != "func"
        end

        def render_node(node)
          text = render_score(node.score)
          desc = render_description(node.description)
          text = "#{text}(#{desc})" unless desc.empty?
          text
        end

        def render_description(description)
          text = ''
          text = description.operation if description.operation
          if description.field && description.value
            text += "(#{field(description.field)}:#{value(description.value)})"
          elsif description.field
            text += "(#{field(description.field)})"
          end
          text
        end

        def field(str)
          ansi(str, :blue ,:bright)
        end

        def value(str)
          ansi(str, :green)
        end

        def wrap_paren(string)
          if string.start_with?("(") && string.end_with?(")")
            string
          else
            "(" + string + ")"
          end
        end
      end
    end
  end
end
