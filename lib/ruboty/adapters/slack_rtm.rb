require 'slack-rtmapi'
require 'ruboty/adapters/base'

module Ruboty
  module Adapters
    class SlackRTM < Base
      env :SLACK_TOKEN, "Account's token. get one on https://api.slack.com/web#basics"

      def run
        init
        bind
        connect
      end

      def say(message)
      end

      private

      def init
      end

      def bind
        client.on(:message) do |data|
          p data
        end
      end

      def connect
        client.main_loop
      end

      def url
        @url ||= ::SlackRTM.get_url(token: ::ENV['SLACK_TOKEN'])
      end

      def client
        @client ||= ::SlackRTM::Client.new(websocket_url: url)
      end
    end
  end
end
