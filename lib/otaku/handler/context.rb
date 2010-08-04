module Otaku
  class Handler
    class Context #:nodoc:

      attr_reader :code

      def initialize(methods_hash)
        @code = 'Class.new{ %s }.new' %
          methods_hash.map do |method, val|
            "def #{method}; Encoder.decode(%|#{Encoder.encode(val).gsub('|','\|')}|); end"
          end.sort.join('; ')
      end

      def eval!
        eval(@code, nil, '(generated class)', 1)
      end

    end
  end
end

