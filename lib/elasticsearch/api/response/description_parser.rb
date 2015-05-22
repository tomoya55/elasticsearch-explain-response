module Elasticsearch
  module API
    module Response
      class DescriptionParser
        attr_reader :description

        def initialize(description)
          @description = description
        end

        def parse
          parse_description
          Description.new(
            raw: description,
            score_type: score_type,
            operation: @operation,
            field: @field,
            value: @value,
          )
        end

        private

        def parse_description
          case description
          when /\Aweight\((\w+)\:(\w+)\s+in\s+\d+\)\s+\[\w+\]\,\s+result\s+of\:\z/
            @operation = "weight"
            @field = $1
            @value = $2
          when /\Aidf\(docFreq\=(\d+)\,\s+maxDocs\=(\d+)\)\z/
            @operation = "idf(#{$1}/#{$2})"
          when /\Atf\(freq\=([\d.]+)\)\, with freq of\:\z/
            @operation = "tf(#{$1})"
          when /\Ascore\(doc\=\d+\,freq=[\d\.]+\)\,\sproduct\sof\:\z/
            @operation = "score"
          when /\Amatch filter\: (?:cache\()?(?:\w+\()?([\w\.\*]+)\:(.*)\)*\z/,
               /\Amatch filter\: QueryWrapperFilter\(([\w\.\*]+)\:([\w\*]+)\)\z/
             @operation = "match"
             @field = $1
             @value = $2
          when /\AFunction for field ([\w\_]+)\:\z/
            @operation = "func(#{field($1)})"
          when /\A(queryWeight|fieldWeight|fieldNorm)/
            @operation = $1
          when /\Afunction\sscore/
            nil
          when "static boost factor", "boostFactor"
            @operation = "boost"
          when "product of:"
            @operation = "product"
          when "Math.min of", "sum of:"
            nil
          else
            @operation = description
          end
        end

        def score_type
          case
          when description.include?("product of")
            "x"
          when description.include?("[multiply]")
            "x"
          when description.include?("sum of")
            "+"
          when description.include?("Math.min of")
            "min"
          else
            " "
          end
        end
      end
    end
  end
end
