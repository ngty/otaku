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

  end
end
