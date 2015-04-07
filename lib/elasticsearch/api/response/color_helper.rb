module Elasticsearch
  module API
    module Response
      module ColorHelper
        def colorized?
          unless @ansi_loaded
            @colorized = load_ansi
          else
            !!@colorized
          end
        end

        def diable_colorization
          @ansi_loaded = true
          @colorized = false
        end

        def load_ansi
          require "ansi/core"
          true
        rescue LoadError
          false
        end

        def ansi(str, *codes)
          if colorized?
            str.to_s.ansi(*codes)
          else
            str.to_s
          end
        end
      end
    end
  end
end
