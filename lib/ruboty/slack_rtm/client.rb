require 'json'
require 'websocket-client-simple'

module Ruboty
  module SlackRTM
    class Client
      def initialize(websocket_url:)
        @client = WebSocket::Client::Simple.connect(websocket_url.to_s)
        @queue = Queue.new
      end

      def send(data)
        data[:id] = Time.now.to_i * 10 + rand(10)
        @queue.enq(data.to_json)
      end

      def on(event, &block)
        @client.on(event) do |message|
          block.call(JSON.parse(message.data))
        end
      end

      def main_loop
        loop do
          message = @queue.deq
          @client.send(message)
        end
      end
    end
  end
end
