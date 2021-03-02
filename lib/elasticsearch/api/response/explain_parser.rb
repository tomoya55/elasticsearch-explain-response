require "elasticsearch/api/response/helpers/string_helper"

module Elasticsearch
  module API
    module Response
      class ExplainParser
        include Helpers::StringHelper

        # @param [Hash<String, Proc<Float>>] script_translation_map: {}
        #   @example {
        #     "doc['has_custom_boost'].value":
        #       ->(value) { value == 1 ? 'Has a custom boost' : 'Does not have a custom boost'
        #     "doc['response_rate'].value >= 0.5 ? 1 : 0":
        #       ->(value) { value == 1 ? 'Has a good response rate' : 'Has a bad response rate <50%'
        #   }
        def initialize(script_translation_map: {})
          @script_translation_map = script_translation_map
        end

        def parse(explain_tree)
          root = create_node(explain_tree, level: 0)
          parse_details(root)
          root
        end

        private

        def create_node(detail, level:)
          ExplainNode.new(
            score: detail["value"] || 0.0,
            description: parse_description(detail["description"], node_value: detail["value"] || 0.0),
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

        def parse_description(description, node_value:)
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
            content = content[0..-2] if content.end_with?(')')
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
          when /\Afunction score\, score mode \[sum\]\z/
            type = "func score"
            operator = "+"
          when /\Ascript score function\, computed with script:\"(?<s>.+)\"\s*(?:and parameters:\s*(?<p>.+))?/m
            operation = "script"
            script, param = $~[:s], $~[:p]
            param.gsub!("\n", '') if param
            script = script.gsub("\n", '')
            if (script_translator = translator_of_custom_script_function(script))
              type = "translated_script"
              field = 'Custom script'
              value = script_translator.call(node_value)
            else
              type = "script"
              script = "\"#{script}\""
              field = script.scan(/doc\[\'([\w\.]+)\'\]/).flatten.uniq.compact.join(" ")
              value = [script, param].join(" ")
            end
          when /\AConstantScore\(.+\), product of\:\z/
            type = "constant"
            operation = "constant"
          when /\Aconstant score/
            type = "constant"
            operation = "constant"
          when "static boost factor", "boostFactor"
            type = "boost"
            operation = "boost"
          when /product\sof\:?/, "[multiply]"
            type = "product"
            operation = "product"
            operator = "x"
          when "Math.min of"
            type = "min"
            operator = "min"
          when "Math.max of"
            type = "max"
            operator = "max"
          when /sum of\:?/
            type = "sum"
            operator = "+"
          when "maxBoost"
            type = "maxBoost"
          when /_score\:\s*/
            type = "score"
            operation = "score"
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

        # @param [String] ES script
        #
        # @return [Lambda]
        # @yieldparam [Float] Associated ES score
        #
        def translator_of_custom_script_function(script)
          code = script[/.*Code\='([^\,]*)\'/,1]
          @script_translation_map[code]
        end
      end
    end
  end
end
