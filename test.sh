#!/bin/sh
set -x

export TEST_QUEUE_WORKERS=2 TEST_QUEUE_VERBOSE=1

export BUNDLE_GEMFILE=Gemfile-minitest4
bundle install
bundle exec minitest-queue ./test/*_minitest4.rb
bundle exec minitest-queue ./test/*_minispec.rb
