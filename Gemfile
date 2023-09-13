source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }
git_source(:bc)     { |repo| "https://github.com/basecamp/#{repo}" }

# Specify your gem's dependencies in mission_control-jobs.gemspec.
gemspec

gem "sqlite3"

gem "sprockets-rails"
gem "solid_queue", bc: "solid_queue", require: false
gem "rubocop-37signals", bc: "house-style", require: false
gem "puma"
