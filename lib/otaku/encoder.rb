module Otaku
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
end
