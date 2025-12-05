# frozen_string_literal: true

source "https://rubygems.org"

# Specify the gem's dependencies in gbln.gemspec
gemspec

# Development dependencies
group :development do
  gem "rake", "~> 13.0"
  gem "yard", "~> 0.9"
end

group :test do
  gem "rspec", "~> 3.12"
  gem "simplecov", "~> 0.22"
  gem "rubocop", "~> 1.50"
  gem "rubocop-rspec", "~> 2.20"
end

# Platform-specific gems
platforms :ruby do
  gem "ffi", "~> 1.15"
end
