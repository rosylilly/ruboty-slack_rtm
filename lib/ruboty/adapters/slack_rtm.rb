require 'time'
require 'slack'
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
        realtime.send(
          type: 'message',
          channel: message[:to],
          text: message[:code] ?  "```\n#{message[:body]}\n```" : message[:body],
          mrkdwn: true
        )
      end

      private

      def init
        response = client.auth_test
        @user_info_caches = {}
        @channel_info_cahces = {}

        ENV['RUBOTY_NAME'] ||= response['user']
      end

      def bind
        realtime.on(:message) do |data|
          method_name = "on_#{data['type']}".to_sym
          send(method_name, data) if respond_to?(method_name, true)
        end
      end

      def connect
        Thread.start do
          loop do
            sleep 5
            set_active
          end
        end

        realtime.main_loop
      end

      def url
        @url ||= ::SlackRTM.get_url(token: ENV['SLACK_TOKEN'])
      end

      def client
        @client ||= ::Slack::Client.new(token: ENV['SLACK_TOKEN'])
      end

      def realtime
        @realtime ||= ::SlackRTM::Client.new(websocket_url: url)
      end

      def set_active
        client.users_setActive
      end

      # event handlers

      def on_message(data)
        data = resolve_mention!(data)
        user = user_info(data['user'])

        robot.receive(
          body: data['text'],
          from: data['channel'],
          from_name: user['name'],
          to: data['channel'],
          channel: channel_info(data['channel']),
          user: user,
          time: Time.at(data['ts'].to_f)
        )
      end

      def on_channel_change(data)
        channel_id = data['channel']
        channel_id = channel_id['id'] if channel_id.is_a?(Hash)
        @channel_info_cahces[channel_id] = nil
      end
      alias_method :on_channel_deleted, :on_channel_change
      alias_method :on_channel_renamed, :on_channel_change
      alias_method :on_channel_archived, :on_channel_change
      alias_method :on_channel_unarchived, :on_channel_change

      def on_user_change(data)
        user = data['user'] || data['bot']
        @user_info_caches[user['id']] = user
      end
      alias_method :on_bot_added, :on_user_change
      alias_method :on_bot_changed, :on_user_change

      def resolve_mention!(data)
        data = data.dup

        data['mention_to'] = []

        data['text'].gsub!(/\<\@(?<uid>[0-9A-Z]+)\>/) do |_|
          user = user_info(Regexp.last_match[:uid])

          data['mention_to'] << user

          "@#{user['name']}"
        end

        data
      end

      def user_info(user_id)
        @user_info_caches[user_id] ||= begin
          resp = client.users_info(user: user_id)

          resp['user']
        end
      end

      def channel_info(channel_id)
        @channel_info_cahces[channel_id] ||= begin
          resp = case channel_id
            when /^C/
              client.channels_info(channel: channel_id)
            else
              {}
            end

          resp['channel']
        end
      end
    end
  end
end
