module Elasticsearch
  module API
    module Response
      class ExplainNode
        attr_reader :score, :description, :details, :level
        attr_accessor :children

        def initialize(score:, description:, details: [], level: 0)
          @score = score
          @description = description
          @details = details
          @level = level
          @children = []
        end

        def operator
          description.operator
        end

        def type
          description.type
        end
      end
    end
  end
end
