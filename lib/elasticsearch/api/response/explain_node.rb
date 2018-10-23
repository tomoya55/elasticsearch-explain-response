require "elasticsearch/api/response/renderable"
require 'forwardable'

module Elasticsearch
  module API
    module Response
      class ExplainNode
        include Renderable
        extend ::Forwardable

        attr_reader :score, :description, :details, :level
        attr_accessor :children

        def_delegators :@description, :type, :operator, :operation, :field, :value

        def initialize(score:, description:, details: [], level: 0)
          @score = score
          @description = description
          @details = details
          @level = level
          @children = []
        end

        def clone_with(attributes = {})
          node = self.class.new(
            score: attributes[:score] || score,
            description: attributes[:description] || description,
            details: attributes[:details] || details,
            level: attributes[:level] || level
          )
          node.children = attributes[:children] || children
          node
        end

        def score_one?
          score == 1.0
        end

        def score?
          type == "score"
        end

        def min?
          type == "min"
        end

        def func?
          type == "func"
        end

        def product?
          type == "product"
        end

        def constant?
          type == "constant"
        end

        def match?
          type == "match"
        end

        def match_all?
          type == "match" && field == "*" && value == "*"
        end

        def boost?
          type == "boost"
        end

        def max_boost?
          type == "maxBoost"
        end

        def func_score?
          type == "func score"
        end

        def query_boost?
          type == "queryBoost"
        end

        def script?
          type == "script"
        end

        def has_children?
          children.any?
        end

        def as_json
          { score: score }.merge(description.as_json)
        end
      end
    end
  end
end
