module Otaku
  class Handler
    class Processor #:nodoc:

      extend Forwardable
      %w{file line code eval!}.each do |meth|
        def_delegator :@magic_proc, meth.to_sym
      end

      def initialize(block)
        @magic_proc = MagicProc.new(block)
      end

      private

        class MagicProc < Handler::MagicProc
          def code_regexp
            @code_regexp ||=
              /^(.*?(Otaku\.start.*?|lambda|proc|Proc\.new)\s*(do|\{)\s*\|(\w+)\|\s*)/m
          end
        end

    end
  end
end

