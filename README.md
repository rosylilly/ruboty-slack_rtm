# Ruboty::SlackRTM

Slack(real time api) adapter for [ruboty](https://github.com/r7kamura/ruboty).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ruboty-slack_rtm'
```

## ENV

- `SLACK_TOKEN`: Account's token. get one on https://api.slack.com/web#basics
- `SLACK_EXPOSE_CHANNEL_NAME`: if this set to 1, `message.to` will be channel name instead of id (optional)
- `SLACK_IGNORE_GENERAL`: if this set to 1, bot ignores all messages on #general channel (optional)

This adapter doesn't require a real user account. Using with bot integration's API token is recommended.
See: https://api.slack.com/bot-users

## Contributing

1. Fork it ( https://github.com/rosylilly/ruboty-slack_rtm/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
