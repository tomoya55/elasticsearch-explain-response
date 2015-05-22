module Elasticsearch
  module API
    module Response
      class ExplainNode
        attr_reader :score, :description, :details, :level, :children

        def initialize(attrs, level: 0)
          @score = attrs["value"]
          @description = DescriptionParser.new(attrs["description"]).parse
          @details = attrs["details"] || []
          @level = level
          @children = []
        end

        def score_type
          description.score_type
        end

        def parse_details
          details.each do |detail|
            child = ExplainNode.new(detail, level: level.succ)
            child.parse_details
            self.children << child
          end
          children
        end
      end
    end
  end
end
