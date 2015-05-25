module Elasticsearch
  module API
    module Response
      class ExplainParser
        def parse(explain_tree)
          root = create_node(explain_tree, level: 0)
          parse_details(root)
          root
        end

        private

        def create_node(detail, level:)
          ExplainNode.new(
            score: detail["value"] || 0.0,
            description: parse_description(detail["description"]),
            details: detail["details"] || [],
            level: level
          )
        end

        def parse_details(node)
          node.details.each do |detail|
            child = create_node(detail, level: node.level.succ)
            node.children << child
            parse_details(child)
          end
        end

        def parse_description(description)
          case description
          when /\Aweight\((\w+)\:(\w+)\s+in\s+\d+\)\s+\[\w+\]\,\s+result\s+of\:\z/
            operation = "weight"
            field = $1
            value = $2
          when /\Aidf\(docFreq\=(\d+)\,\s+maxDocs\=(\d+)\)\z/
            operation = "idf(#{$1}/#{$2})"
          when /\Atf\(freq\=([\d.]+)\)\, with freq of\:\z/
            operation = "tf(#{$1})"
          when /\Ascore\(doc\=\d+\,freq=[\d\.]+\)\,\sproduct\sof\:\z/
            operation = "score"
          when /\Amatch filter\: (?:cache\()?(?:\w+\()?([\w\.\*]+)\:(.*)\)*\z/,
               /\Amatch filter\: QueryWrapperFilter\(([\w\.\*]+)\:([\w\*]+)\)\z/
             operation = "match"
             field = $1
             value = $2
          when /\AFunction for field ([\w\_]+)\:\z/
            operation = "func"
            field = $1
          when /\A(queryWeight|fieldWeight|fieldNorm)/
            operation = $1
          when /\Afunction\sscore/
            nil
          when "static boost factor", "boostFactor"
            operation = "boost"
          when "product of:"
            operation = "product"
          when "Math.min of", "sum of:"
            nil
          else
            operation = description
          end

          Description.new(
            raw: description,
            score_type: score_type(description),
            operation: operation,
            field: field,
            value: value,
          )
        end

        def score_type(description)
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
