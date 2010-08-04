module Otaku
  class Handler
    class Processor #:nodoc:

      extend Forwardable
      def_delegator :@magic_proc, :file
      def_delegator :@magic_proc, :line
      def_delegator :@magic_proc, :code

      def initialize(block)
        @magic_proc = MagicProc.new(block)
      end

      def eval!
        eval(code, nil, file, line)
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

