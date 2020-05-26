
# frozen_string_literal: true

source 'https://rubygems.org'

# Required to fix issue with FakeFS; refer to
# https://github.com/fakefs/fakefs#fakefs-----typeerror-superclass-mismatch-for-class-file.
require 'pp'

git_source(:github) {|repo_name| "https://github.com/#{repo_name}" }

# Forked of a fork containing a logger fix. The main gem can be used
# again once StructuredWarnings is removed
gem 'rubytree', github: 'alces-software/RubyTree'

gem 'nodeattr_utils'
gem 'flight_config'
gem 'commander-openflighthpc'

gem 'activesupport', '~> 5.2.4'
gem 'colorize'
gem 'dry-validation', '~> 0.13.3'
gem 'hashie'
gem 'highline', '1.7.8'
gem 'network_interface', '~> 0.0.1'
gem 'recursive-open-struct'
gem 'ruby-progressbar'
gem 'rubyzip'
gem 'terminal-table'

group :development do
  gem 'fakefs'
  gem 'rspec'
  gem 'simplecov'

  gem "bundler"
  gem 'pry'
  gem 'pry-byebug'
  gem 'rake'
  gem 'rubocop', '~> 0.52.1'
  gem 'rubocop-rspec'
end
