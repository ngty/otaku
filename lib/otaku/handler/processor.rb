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

      def marshal_dump
        [@magic_proc]
      end

      def marshal_load(data)
        @magic_proc, _ = data
      end

      private

        class MagicProc < Handler::MagicProc

          def code_fragments
            ignore, start_marker, arg =
              [:ignore, :start_marker, :arg].map{|key| code_match_args[key] }
            [
              "proc #{start_marker} |#{arg}| ",
              source_code.sub(ignore, '')
            ]
          end

          def sexp_regexp
            @cache[:sexp_regexp] ||= (
              Regexp.new([
                Regexp.quote("s(:iter, s(:call, nil, :"),
                "(proc|lambda)",
                Regexp.quote(", s(:arglist)), s(:lasgn, :#{code_match_args[:arg]}), s("),
              ].join)
            )
          end

          def code_regexp
            @cache[:code_regexp] ||=
              /^(.*?(Otaku\.start.*?|lambda|proc|Proc\.new)\s*(do|\{)\s*(\|(\w+)\|\s*))/m
          end

        end

    end
  end
end

