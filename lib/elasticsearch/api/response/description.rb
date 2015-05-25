module Elasticsearch
  module API
    module Response
      class Description
        attr_reader :raw, :score_type, :operation, :field, :value

        def initialize(raw:, score_type:, operation: nil, field: nil, value: nil)
          @raw = raw
          @score_type = score_type
          @operation = operation
          @field = field
          @value = value
        end
      end
    end
  end
end
