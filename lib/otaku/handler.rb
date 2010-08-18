module Otaku
  class Handler

    extend Forwardable
    def_delegator :@proc, :root

    def initialize(handler)
      @proc = SerializableProc.new(&handler)
    end

    def process(data)
      @proc.call(data)
    end

    def marshal_dump
      @proc
    end

    def marshal_load(data)
      @proc = data
    end

    private

      class SerializableProc < ::SerializableProc #:nodoc:
        def root
          File.dirname(@file)
        end
      end

  end

end
