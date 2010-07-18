module Otaku
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
