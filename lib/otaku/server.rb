module Otaku
  module Server

    class << self

      attr_accessor :handler

      def start(other_process=false)
        other_process ? run_evented_server : (
          # print '[Otaku] initializing at %s:%s ... ' % [Otaku.address, Otaku.port] # DEBUG
          run_server_script
          # puts 'done [pid#%s]' % @process.pid # DEBUG
        )
      end

      def run_evented_server
        Otaku.log 'started with pid #%s' % Process.pid,
          'listening at %s:%s' % [Otaku.address, Otaku.port]
        EventMachine::run { EventMachine::start_server(Otaku.address, Otaku.port, EM) }
      end

      def run_server_script
        script = File.join(File.dirname(__FILE__), '..', 'otaku.rb')
        args = Encoder.encode(:config => Otaku.config, :handler => @handler)
        @process = IO.popen(%|#{Otaku.ruby} #{script} "#{args.gsub('"','\"')}"|,'r')
        sleep Otaku.init_wait_time
      end

      def stop
        Process.kill('SIGHUP', @process.pid) if @process
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

        def log(*msgs)
          Otaku.log(msgs)
        end

      end

  end
end
