# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ruboty/slack_rtm/version'

Gem::Specification.new do |spec|
  spec.name          = 'ruboty-slack_rtm'
  spec.version       = Ruboty::SlackRTM::VERSION
  spec.authors       = ['Sho Kusano']
  spec.email         = ['rosylilly@aduca.org']
  spec.summary       = 'Slack real time messaging adapter for Ruboty'
  spec.description   = spec.summary
  spec.homepage      = 'https://github.com/rosylilly/ruboty-slack_rtm'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rubocop', '>= 0.28.0'

  spec.add_dependency 'ruboty', '>= 1.1.4'
  spec.add_dependency 'slack-api', '~> 1.0.0'
  spec.add_dependency 'websocket-client-simple', '~> 0.3.0'
end
