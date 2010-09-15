module Otaku
  class Handler

    def initialize(handler)
      @proc = SerializableProc.new(&handler)
    end

    def process(data)
      @proc.call(data)
    end

    def root
      @proc.file
    end

    def marshal_dump
      @proc
    end

    def marshal_load(data)
      @proc = data
    end

  end

  class ::SerializableProc
    attr_reader :file
  end

end
