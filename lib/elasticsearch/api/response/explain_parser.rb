require "elasticsearch/api/response/string_helper"

module Elasticsearch
  module API
    module Response
      class ExplainParser
        include StringHelper

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
          when /\Aweight\((\w+)\:(\w+)\s+in\s+\d+\)\s+\[\w+\]\, result of\:\z/
            type = "weight"
            operation = "weight"
            operator = "x"
            field = $1
            value = $2
          when /\Aidf\(docFreq\=(\d+)\, maxDocs\=(\d+)\)\z/
            type = "idf"
            operation = "idf(#{$1}/#{$2})"
          when /\Atf\(freq\=([\d.]+)\)\, with freq of\:\z/
            type = "tf"
            operation = "tf(#{$1})"
          when /\Ascore\(doc\=\d+\,freq=[\d\.]+\)\, product of\:\z/
            type =  "score"
            operation = "score"
            operator = "x"
          when /\Amatch filter\: (?:cache\()?(?:(?<op>[\w]+)\()*(?<c>.+)\)*\z/
            type = "match"
            operation = "match"
            operation += ".#{$~[:op]}" if $~[:op] && !%w[QueryWrapperFilter].include?($~[:op])
            content = $~[:c]
            hash = tokenize_contents(content)
            field = hash.keys.join(", ")
            value = hash.values.join(", ")
          when /\AFunction for field ([\w\_]+)\:\z/
            type = "func"
            operation = "func"
            field = $1
          when /\AqueryWeight\, product of\:\z/
            type = "queryWeight"
            operation = "queryWeight"
            operator = "x"
          when /\AfieldWeight in \d+\, product of\:\z/
            type = "fieldWeight"
            operation = "fieldWeight"
            operator = "x"
          when /\AqueryNorm/
            type = "queryNorm"
            operation = "queryNorm"
          when /\Afunction score\, product of\:\z/,
            /\Afunction score\, score mode \[multiply\]\z/
            type = "func score"
            operator = "x"
          when /\Ascript score function\, computed with script:\"(?<s>.+)\"\s*(?:and parameters:\s*(?<p>.+))?/m
            type = "script"
            operation = "script"
            script, param = $~[:s], $~[:p]
            script = script.gsub("\n", '')
            script = "\"#{script}\""
            param.gsub!("\n", '') if param
            field = script.scan(/doc\[\'([\w\.]+)\'\]/).flatten.uniq.compact.join(" ")
            value = [script, param].join(" ")
          when "static boost factor", "boostFactor"
            type = "boost"
            operation = "boost"
          when "product of:", "[multiply]"
            type = "product"
            operation = "product"
            operator = "x"
          when "Math.min of"
            type = "min"
            operator = "min"
          when "Math.max of"
            type = "max"
            operator = "max"
          when "sum of:"
            type = "sum"
            operator = "+"
          when "maxBoost"
            type = "maxBoost"
          else
            type = description
            operation = description
          end

          Description.new(
            raw: description,
            type: type,
            operator: operator,
            operation: operation,
            field: field,
            value: value,
          )
        end
      end
    end
  end
end
