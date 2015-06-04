require 'cgi'
require 'time'
require 'slack'
require 'slack-rtmapi'
require 'ruboty/adapters/base'

module Ruboty
  module Adapters
    class SlackRTM < Base
      env :SLACK_TOKEN, "Account's token. get one on https://api.slack.com/web#basics"
      env :SLACK_EXPOSE_CHANNEL_NAME, "if this set to 1, message.to will be channel name instead of id", optional: true

      def run
        init
        bind
        connect
      end

      def say(message)
        channel = message[:to]
        if channel[0] == '#'
          channel = resolve_channel_id(channel[1..-1])
        end

        return unless channel

        realtime.send(
          type: 'message',
          channel: channel,
          text: message[:code] ?  "```\n#{message[:body]}\n```" : resolve_send_mention(message[:body]),
          mrkdwn: true
        )
      end

      private

      def init
        response = client.auth_test
        @user_info_caches = {}
        @channel_info_caches = {}

        ENV['RUBOTY_NAME'] ||= response['user']

        make_users_cache
        make_channels_cache
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

      def expose_channel_name?
        if @expose_channel_name.nil?
          @expose_channel_name = ENV['SLACK_EXPOSE_CHANNEL_NAME'] == '1'
        else
          @expose_channel_name
        end
      end

      def set_active
        client.users_setActive
      end

      # event handlers

      def on_message(data)
        data = resolve_mention!(data)
        user = user_info(data['user']) || {}

        channel = channel_info(data['channel'])
        if channel
          channel_to = expose_channel_name? ? "##{channel['name']}" : channel['id']
        else # direct message
          channel_to = data['channel']
        end

        robot.receive(
          body: CGI.unescapeHTML(data['text']),
          from: data['channel'],
          from_name: user['name'],
          to: channel_to,
          channel: channel,
          user: user,
          mention_to: data['mention_to'],
          time: Time.at(data['ts'].to_f)
        )
      end

      def on_channel_change(data)
        make_channels_cache
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

        data['text'] = (data['text'] || '').gsub(/\<\@(?<uid>[0-9A-Z]+)(?:\|(?<name>[^>]+))?\>/) do |_|
          name = Regexp.last_match[:name]

          unless name
            user = user_info(Regexp.last_match[:uid])

            data['mention_to'] << user

            name = user['name']
          end

          "@#{name}"
        end

        data['text'].gsub!(/\<!(?<special>[^>]+)\>/) do |_|
          "@#{Regexp.last_match[:special]}"
        end

        data['text'].gsub!(/\<((?<link>[^>|]+)(?:\|(?<ref>[^>]*))?)\>/) do |_|
          Regexp.last_match[:ref] || Regexp.last_match[:link]
        end


        data['text'].gsub!(/\#(?<room_id>[A-Z0-9]+)/) do |_|
          room_id = Regexp.last_match[:room_id]
          msg = "##{room_id}"

          if channel = channel_info(room_id)
            msg = "##{channel['name']}"
          end

          msg
        end

        data
      end

      def resolve_send_mention(text)
        text = text.to_s
        text.gsub!(/@(?<mention>[0-9a-z._-]+)/) do |_|
          mention = Regexp.last_match[:mention]
          msg = "@#{mention}"

          @user_info_caches.each_pair do |id, user|
            if user['name'].downcase == mention.downcase
              msg = "<@#{id}>"
            end
          end

          msg
        end

        text.gsub!(/@(?<special>(?:everyone|group|channel))/) do |_|
          "<!#{Regexp.last_match[:special]}>"
        end

        text.gsub!(/\#(?<room_id>[a-z0-9_-]+)/) do |_|
          room_id = Regexp.last_match[:room_id]
          msg = "##{room_id}"

          @channel_info_caches.each_pair do |id, channel|
            if channel && channel['name'] == room_id
              msg = "<##{id}|#{room_id}>"
            end
          end

          msg
        end

        text
      end

      def make_users_cache
        resp = client.users_list
        if resp['ok']
          resp['members'].each do |user|
            @user_info_caches[user['id']] = user
          end
        end
      end

      def make_channels_cache
        resp = client.channels_list
        if resp['ok']
          resp['channels'].each do |channel|
            @channel_info_caches[channel['id']] = channel
          end
        end
      end

      def user_info(user_id)
        return {} if user_id.to_s.empty?

        @user_info_caches[user_id] ||= begin
          resp = client.users_info(user: user_id)

          resp['user']
        end
      end

      def channel_info(channel_id)
        @channel_info_caches[channel_id] ||= begin
          resp = case channel_id
            when /^C/
              client.channels_info(channel: channel_id)
            else
              {}
            end

          resp['channel']
        end
      end

      def resolve_channel_id(name)
        ret_id = nil
        @channel_info_cahces.each_pair do |id, channel|
          if channel['name'] == name
            ret_id = id
            break
          end
        end
        return ret_id
      end
    end
  end
end
