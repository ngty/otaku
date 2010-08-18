require 'rubygems'
require 'forwardable'
require 'eventmachine'
require 'logger'
require 'base64'
require 'serializable_proc'

require 'otaku/encoder'
require 'otaku/handler'
require 'otaku/server'
require 'otaku/client'

module Otaku

  class HandlerNotDefinedError < Exception ; end
  class DataProcessError < Exception ; end

  # Registers support for serializable proc (only needed for static code analysis)
  SerializableProc::Parsers::Static.matchers << 'Otaku\.start'

  DEFAULTS = {
    :ruby => 'ruby',
    :address => '127.0.0.1',
    :port => 10999,
    :log_file => '/tmp/otaku.log',
    :init_wait_time => 2 * (RUBY_PLATFORM =~ /java/i ? 5 : 1)
  }

  class << self

    attr_accessor *DEFAULTS.keys

    def configure(config = {}, &block)
      block_given? ? yield(self) :
        config.each{|name, val| send(:"#{name}=", val) }
    end

    def config
      DEFAULTS.keys.inject({}) do |memo, name|
        memo.merge(name => send(name))
      end
    end

    def root
      File.expand_path(File.dirname(__FILE__))
    end

    def start(&handler)
      raise HandlerNotDefinedError unless block_given?
      Server.handler = Handler.new(handler)
      Server.start
    end

    def stop
      Server.stop
    end

    def process(data)
      Client.get(data)
    end

    def log(*msgs)
      @logger ||= Logger.new(Otaku.log_file)
      [msgs].flatten.each{|msg| @logger << "[Otaku] %s\n" % msg }
    end

    def cleanup
      @logger.close if @logger
    end

    # NOTE: Unexpected, it is possible for otaku to be required multiple times,
    # we wanna avoid the irritating warning issued when DEFAULTS is redeclared.
    Otaku.configure(DEFAULTS)

  end

end

if $0 == __FILE__ && (encoded_data = ARGV[0])
  begin
    include Otaku
    data = Encoder.decode(encoded_data)
    Otaku.configure(data[:config])
    Server.handler = data[:handler]
    Server.start(true)
  rescue
    Otaku.log $!.inspect
  ensure
    Otaku.cleanup
  end
end
