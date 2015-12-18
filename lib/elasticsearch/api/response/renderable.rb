module Elasticsearch
  module API
    module Response
      module Renderable
        def render(rendering_options = {})
          tree = block_given? ? yield(self) : self
          Renderers::StandardRenderer.new({ colorize: true }.merge(rendering_options)).render(tree)
        end

        def render_in_line(rendering_options = {})
          tree = block_given? ? yield(self) : self
          Renderers::InlineRenderer.new({ colorize: true }.merge(rendering_options)).render(tree)
        end

        def render_as_hash(rendering_options = {})
          tree = block_given? ? yield(self) : self
          Renderers::HashRenderer.new.render(tree)
        end
      end
    end
  end
end
