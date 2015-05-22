require "elasticsearch/api/response/color_helper"

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
        include ColorHelper

        class << self
          # Show scoring as a simple math formula
          # @example
          #    "1.0 = (1.0(termFreq=1.0)) x 1.0(idf(2/3)) x 1.0(fieldNorm)"
          def render_in_line(result, max: nil)
            new(result["explanation"], max: max).render_in_line
          end

          # Show scoring with indents
          # @example
          #   60.62 = 1.12 x 54.3 x 1.0(queryBoost)
          #     1.12 = 3.35 x 0.33(coord(4/12))
          #       3.35 = 0.2 + 0.93 + 1.29 + 0.93
          #     54.3 = 54.3 min 3.4028234999999995e+38(maxBoost)
          #       54.3 = 2.0 x 10.0 x 3.0 x 0.91
          def render(result, max: nil)
            parser = new(result["explanation"], max: max)
            parser.parse
            parser.render
          end
        end

        attr_reader :explain

        def initialize(explain, max: nil)
          @explain = explain
          @indent = 0
          @max = max || 3
        end

        def render
          @buffer = []
          parse_explain(explain, indent: @indent, max: @max)
          @buffer.map do |buf|
            render_result(buf[:score], render_details(buf[:details], indent: @max + 1), indent: buf[:indent])
          end
        end

        def render_in_line
          score = explain["value"]
          details = parse_for_oneline(explain)
          render_result(score, render_details(details, indent: 0))
        end

        private

        def get_score_type(description)
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

        def extract_description(description)
          case description
          when /\Aweight\((\w+)\:(\w+)\s+in\s+\d+\)\s+\[\w+\]\,\s+result\s+of\:\z/
            [field($1), value($2)].join(':')
          when /\Aidf\(docFreq\=(\d+)\,\s+maxDocs\=(\d+)\)\z/
            "idf(#{$1}/#{$2})"
          when /\Atf\(freq\=([\d.]+)\)\, with freq of\:\z/
            "tf(#{$1})"
          when /\Ascore\(doc\=\d+\,freq=[\d\.]+\)\,\sproduct\sof\:\z/
            "score"
          when /\Amatch filter\: (?:cache\()?(?:\w+\()?([\w\.\*]+)\:(.*)\)*\z/,
               /\Amatch filter\: QueryWrapperFilter\(([\w\.\*]+)\:([\w\*]+)\)\z/
            "match(#{field($1)}:#{value($2)})"
          when /\AFunction for field ([\w\_]+)\:\z/
            "func(#{field($1)})"
          when /\A(queryWeight|fieldWeight|fieldNorm)/
            $1
          when /\Afunction\sscore/
            nil
          when "static boost factor", "boostFactor"
            "boost"
          when "Math.min of", "sum of:", "product of:"
            nil
          else
            description
          end
        end

        def field(str)
          ansi(str, :blue ,:bright)
        end

        def value(str)
          ansi(str, :green)
        end

        def render_details(details, indent:)
          details[:details].map do |de|
            case de
            when Hash
              if indent < @max
                detail = render_details(de, indent: indent.succ)
                wrap_paren(detail)
              else
                de[:description]
              end
            else
              de
            end
          end.join(" #{details[:symbol]} ")
        end

        def parse_for_oneline(explain)
          symbol = get_score_type(explain["description"])
          description = parse_description(explain)
          details = explain["details"].map do |de|
            if de["details"]
              parse_for_oneline(de)
            else
              parse_description(de)
            end
          end
          {details: details, symbol: symbol, description: description}
        end

        def parse_description(detail)
          text = render_score(detail["value"])
          description = extract_description(detail["description"])
          text += "(#{description})" if description
          text
        end

        def parse_explain(explain, indent:, max: )
          return if indent > max
          score = explain["value"]
          symbol = get_score_type(explain["description"])
          details = explain["details"].map(&method(:parse_description))
          @buffer << {score: score, details: {details: details, symbol: symbol}, indent: indent}

          explain["details"].each do |de|
            parse_explain(de, indent: indent.succ, max: max) if de["details"]
          end
        end

        def render_score(score)
          ansi(score.round(2).to_s, :magenta, :bright)
        end

        def render_result(score, details, indent: 0)
          " " * indent * 2 + [render_score(score), "=", details].flatten.join(" ")
        end

        def wrap_paren(string)
          if string.start_with?("(") && string.end_with?(")")
            string
          else
            "(" + string + ")"
          end
        end
      end
    end
  end
end
