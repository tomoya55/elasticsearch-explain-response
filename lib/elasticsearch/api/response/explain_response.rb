require "elasticsearch/api/response/explain_node"
require "elasticsearch/api/response/description"
require "elasticsearch/api/response/explain_parser"
require "elasticsearch/api/response/explain_trimmer"
require "elasticsearch/api/response/renderers/standard_renderer"
require "elasticsearch/api/response/renderers/inline_renderer"
require "elasticsearch/api/response/renderers/hash_renderer"

module Elasticsearch
  module API
    module Response
      # Parse Elasticsearch Explain API response json and display them in a neat way
      #
      # @example
      #    require 'elasticsearch'
      #    client = Elasticsearch::Client.new
      #    result = client.explain index: "megacorp", type: "employee", id: "1", q: "last_name:Smith"
      #    Elasticsearch::API::Response::ExplainResponse.new(result["explanation"]).render_in_line
      #      #=> "1.0 = (1.0(termFreq=1.0)) x 1.0(idf(2/3)) x 1.0(fieldNorm)"
      class ExplainResponse
        class << self
          # Show scoring as a simple math formula
          # @example
          #    "1.0 = (1.0(termFreq=1.0)) x 1.0(idf(2/3)) x 1.0(fieldNorm)"
          def render_in_line(result, options = {}, &block)
            new(result["explanation"], options).render_in_line(&block)
          end

          # Show scoring with indents
          # @example
          #   60.62 = 1.12 x 54.3 x 1.0(queryBoost)
          #     1.12 = 3.35 x 0.33(coord(4/12))
          #       3.35 = 0.2 + 0.93 + 1.29 + 0.93
          #     54.3 = 54.3 min 3.4028234999999995e+38(maxBoost)
          #       54.3 = 2.0 x 10.0 x 3.0 x 0.91
          def render(result, options = {}, &block)
            new(result["explanation"], options).render(&block)
          end

          def result_as_hash(result, options = {})
            new(result["explanation"], options).render_as_hash
          end
        end

        attr_reader :explain, :trim, :rendering_options

        def initialize(explain, options = {})
          @explain = explain || {}
          @indent = 0
          @trim = options.key?(:trim) ? options.delete(:trim) : true
          @script_translation_map = options.delete(:script_translation_map) || {}
          @rendering_options = options

          parse_details
        end

        def render(&block)
          @root.render(rendering_options, &block)
        end

        def render_in_line(&block)
          @root.render_in_line(rendering_options, &block)
        end

        def render_as_hash(&block)
          @root.render_as_hash(rendering_options, &block)
        end

        private

        def parse_details
          @root ||= begin
            tree = ExplainParser.new(script_translation_map: @script_translation_map).parse(explain)
            tree = ExplainTrimmer.new.trim(tree) if trim
            tree
          end
        end
      end
    end
  end
end
