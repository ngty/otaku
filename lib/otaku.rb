require 'rubygems'
require 'eventmachine'
require 'logger'
require 'base64'
require 'ruby2ruby'

# TODO: Preliminary try, should be removed eventually !!
require 'parse_tree'
require 'parse_tree_extensions'

module Otaku

  class HandlerNotDefinedError < Exception ; end

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

    def start(&handler)
      raise HandlerNotDefinedError unless block_given?
      Server.handler = handler
      Server.start
    end

    def stop
      Server.stop
    end

    def process(data)
      Client.get(data)
    end

  end

  DEFAULTS.each do |config, val|
    self.send(:"#{config}=", val)
  end

  module Server

    class << self

      attr_writer :handler

      def start(other_process=false)
        other_process ? run_evented_server : (
          print '[Otaku] initializing at %s:%s ... ' % [Otaku.address, Otaku.port]
          run_server_script
          puts 'done [pid#%s]' % @process.pid
        )
      end

      def run_evented_server
        log 'started with pid #%s' % Process.pid,
          'listening at %s:%s' % [Otaku.address, Otaku.port]
        EventMachine::run { EventMachine::start_server(Otaku.address, Otaku.port, EM) }
      end

      def run_server_script
        args = Base64.encode64(Marshal.dump({
          :config => Otaku.config,
          :handler => Ruby2Ruby.new.process(@handler.to_sexp)
        }))
        @process = IO.popen(%|ruby #{__FILE__} "#{args.gsub('"','\"')}"|,'r')
        sleep Otaku.init_wait_time
      end

      def stop
        Process.kill('SIGHUP', @process.pid) if @process
      end

      def handler
        eval(@handler)
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

      module EM

        def receive_data(data)
          log 'receives data: %s' % data.inspect
          result = process_data(data)
          log 'returning result: %s' % result.inspect
          send_data(Base64.encode64(Marshal.dump(result)))
        end

        def process_data(data)
          begin Server.handler.call(data)
          rescue then log($!.inspect)
          end
        end

        def log(*msg)
          Server.log(*msg)
        end

      end

  end

  module Client

    class << self
      def get(data)
        EventMachine::run do
          EventMachine::connect(Otaku.address, Otaku.port, EM).
            execute(data) do |data|
              @result = Marshal.load(Base64.decode64(data))
            end
        end
        @result
      end
    end

    private

      module EM

        def receive_data(data)
          @callback.call(data)
          EventMachine::stop_event_loop # ends loop & resumes program flow
        end

        def execute(method, &callback)
          @callback = callback
          send_data(method)
        end

      end

  end
end

if $0 == __FILE__
  begin
    Server = Otaku::Server
    data = Marshal.load(Base64.decode64(ARGV[0]))
    Otaku.configure(data[:config])
    Server.handler = data[:handler]
    Server.start(true)
  rescue
    Server.log($!.inspect)
  ensure
    Server.cleanup
  end
end
