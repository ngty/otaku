module Otaku
  class Handler
    class Context #:nodoc:

      attr_reader :code

      def initialize(methods_hash)
        @code = 'Class.new{ %s }.new' %
          methods_hash.map do |method, val|
            'def %s; %s; end' % [method, method_body(val)]
          end.sort.join('; ')
      end

      def eval!
        eval(@code, nil, '(generated class)', 1)
      end

      def marshal_dump
        [@code]
      end

      def marshal_load(data)
        @code, _ = data
      end

      private

        def method_body(val)
          if val.is_a?(Proc)
            "Encoder.decode(%|#{Encoder.encode(magic_proc(val)).gsub('|','\|')}|).eval!"
          else
            "Encoder.decode(%|#{Encoder.encode(val).gsub('|','\|')}|)"
          end
        end

        def magic_proc(block)
          MagicProc.new(block)
        end

    end
  end
end

