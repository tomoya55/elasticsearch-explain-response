module Elasticsearch
  module API
    module Response
      module StringHelper
        WORD = /[\w\.\*]+/
        WITH_QUOTE = /"[^"]*"/
        WITH_BRACKET = /\[[^\]]*\]/
        QUOTE_TOKENIZER = /(?:(?<field>#{WORD})(\:(?<value>(#{WORD}|#{WITH_QUOTE}|#{WITH_BRACKET})))?)+/

        # @return [Hash] field name as a key and values as a value
        def tokenize_contents(string)
          string
            .scan(QUOTE_TOKENIZER)
            .each_with_object(Hash.new{|h,k| h[k] = []}) { |(field, value), memo|
              memo[field] << value
            }
        end
      end
    end
  end
end
