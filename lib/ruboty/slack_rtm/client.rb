require 'json'
require 'websocket-client-simple'

module Ruboty
  module SlackRTM
    class Client
      def initialize(websocket_url:)
        @client = create_client(websocket_url.to_s)

        @queue = Queue.new
      end

      def send_message(data)
        data[:id] = Time.now.to_i * 10 + rand(10)
        @queue.enq(data.to_json)
      end

      def on_text(&block)
        @client.on(:message) do |message|
          case message.type
          when :ping
            Ruboty.logger.debug("#{Client.name}: Received ping message")
            send('', type: 'pong')
          when :pong
            Ruboty.logger.debug("#{Client.name}: Received pong message")
          when :text
            block.call(JSON.parse(message.data))
          else
            Ruboty.logger.warn("#{Client.name}: Received unknown message type=#{message.type}: #{message.data}")
          end
        end
      end

      def main_loop
        keep_connection

        loop do
          message = @queue.deq
          @client.send(message)
        end
      end

      private

      def create_client(url)
        WebSocket::Client::Simple.connect(url, verify_mode: OpenSSL::SSL::VERIFY_PEER).tap do |client|
          client.on(:error) do |err|
            Ruboty.logger.error("#{err.class}: #{err.message}\n#{err.backtrace.join("\n")}")
          end
        end
      end

      def keep_connection
        Thread.start do
          loop do
            sleep(30)
            @client.send('', type: 'ping')
          end
        end
      end
    end
  end
end
