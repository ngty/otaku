require 'rubygems'
require 'eventmachine'
require 'logger'
require 'base64'
require 'ruby2ruby'
require 'ruby_parser'

# TODO: Preliminary try, should be removed eventually !!
require 'parse_tree'
require 'parse_tree_extensions'

module Otaku

  class HandlerNotDefinedError < Exception ; end
  class DataProcessError < Exception ; end

  # //////////////////////////////////////////////////////////////////////////////////////////
  # Otaku
  # //////////////////////////////////////////////////////////////////////////////////////////

  DEFAULTS = {
    :address => '127.0.0.1',
    :port => 10999,
    :log_file => '/tmp/otaku.log',
    :init_wait_time => 2
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

  # //////////////////////////////////////////////////////////////////////////////////////////
  # Otaku::Encoder
  # //////////////////////////////////////////////////////////////////////////////////////////

  module Encoder
    class << self

      def encode(thing)
        Base64.encode64(Marshal.dump(thing))
      end

      def decode(thing)
        Marshal.load(Base64.decode64(thing))
      end

    end
  end

  # //////////////////////////////////////////////////////////////////////////////////////////
  # Otaku::Handler
  # //////////////////////////////////////////////////////////////////////////////////////////

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

  # //////////////////////////////////////////////////////////////////////////////////////////
  # Otaku::Server
  # //////////////////////////////////////////////////////////////////////////////////////////

  module Server

    class << self

      attr_accessor :handler

      def start(other_process=false)
        other_process ? run_evented_server : (
          # print '[Otaku] initializing at %s:%s ... ' % [Otaku.address, Otaku.port] # DBUG
          run_server_script
          # puts 'done [pid#%s]' % @process.pid # DEBUG
        )
      end

      def run_evented_server
        log 'started with pid #%s' % Process.pid,
          'listening at %s:%s' % [Otaku.address, Otaku.port]
        EventMachine::run { EventMachine::start_server(Otaku.address, Otaku.port, EM) }
      end

      def run_server_script
        args = Encoder.encode({
          :config => Otaku.config,
          :handler => @handler
        })
        @process = IO.popen(%|ruby #{__FILE__} "#{args.gsub('"','\"')}"|,'r')
        sleep Otaku.init_wait_time
      end

      def stop
        Process.kill('SIGHUP', @process.pid) if @process
      end

      def log(*msgs)
        @logger ||= Logger.new(Otaku.log_file)
        msgs.each{|msg| @logger << "[Otaku] %s\n" % msg }
      end

      def cleanup
        @logger.close
      end

    end

    private

      module EM #:nodoc:

        def receive_data(data)
          log 'receives data: %s' % data.inspect
          result = process_data(data)
          log 'returning result: %s' % result.inspect
          send_data(Encoder.encode(result))
        end

        def process_data(data)
          begin
            Server.handler[data]
          rescue
            error = DataProcessError.new($!.inspect)
            log(error.inspect)
            error
          end
        end

        def log(*msg)
          Server.log(*msg)
        end

      end

  end

  # //////////////////////////////////////////////////////////////////////////////////////////
  # Otaku::Client
  # //////////////////////////////////////////////////////////////////////////////////////////

  module Client

    class << self
      def get(data)
        EventMachine::run do
          EventMachine::connect(Otaku.address, Otaku.port, EM).
            execute(data) do |data|
              @result = Encoder.decode(data)
            end
        end
        @result
      end
    end

    private

      module EM #:nodoc:

        def receive_data(data)
          result = @callback.call(data)
          result.is_a?(DataProcessError) ? raise(result) : result
          EventMachine::stop_event_loop # ends loop & resumes program flow
        end

        def execute(method, &callback)
          @callback = callback
          send_data(method)
        end

      end

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
