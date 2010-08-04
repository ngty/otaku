require 'otaku/handler/magic_proc'
require 'otaku/handler/context'
require 'otaku/handler/processor'

module Otaku
  class Handler

    attr_reader :context, :processor

    def initialize(context, handler)
      @context = Context.new(context)
      @processor = Processor.new(handler)
    end

    def process(data)
      @context.eval!.instance_exec(data, &@processor.eval!)
    end

    def root
      File.dirname(@processor.file)
    end

    def marshal_dump
      [@context, @processor]
    end

    def marshal_load(data)
      @context, @processor = data
    end

  end
end
