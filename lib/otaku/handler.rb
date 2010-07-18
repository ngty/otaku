module Otaku
  class Handler

    def initialize(context, handler)
      @context = __context_as_code__(context)
      @proc = __proc_as_code__(handler)
    end

    def [](data)
      eval(@context).instance_exec(data, &eval(@proc))
    end

    private

      def __proc_as_code__(block)
        Ruby2Ruby.new.process(block.to_sexp)
      end

      def __context_as_code__(methods_hash)
        'Class.new{ %s }.new' %
          methods_hash.map do |method, val|
            "def #{method}; Encoder.decode(%|#{Encoder.encode(val).gsub('|','\|')}|); end"
          end.join('; ')
      end

  end
end
