module Elasticsearch
  module API
    module Response
      class Description
        attr_reader :raw, :type, :operator, :operation, :field, :value

        def initialize(raw:, type:, operator:, operation: nil, field: nil, value: nil)
          @raw = raw
          @type = type
          @operator = operator
          @operation = operation
          @field = field
          @value = value
        end

        def as_json
          {
            type: type,
            operator: operator,
            operation: operation,
            field: field,
            value: value
          }.delete_if { |k, v| v.nil? }
        end
      end
    end
  end
end
