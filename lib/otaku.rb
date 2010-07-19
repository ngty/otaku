require 'rubygems'
require 'eventmachine'
require 'logger'
require 'base64'
require 'ruby2ruby'
require 'ruby_parser'

$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'otaku/encoder'
require 'otaku/handler'
require 'otaku/server'
require 'otaku/client'

module Otaku

  class HandlerNotDefinedError < Exception ; end
  class DataProcessError < Exception ; end

  DEFAULTS = {
    :ruby => 'ruby',
    :address => '127.0.0.1',
    :port => 10999,
    :log_file => '/tmp/otaku.log',
    :init_wait_time => 2 * (RUBY_PLATFORM =~ /java/i ? 3 : 1)
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

    def start(context = {}, &handler)
      raise HandlerNotDefinedError unless block_given?
      Server.handler = Handler.new(context, handler)
      Server.start
    end

    def stop
      Server.stop
    end

    def process(data)
      Client.get(data)
    end

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
    Server.log($!.inspect)
  ensure
    Server.cleanup
  end
end
