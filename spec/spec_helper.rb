# frozen_string_literal: true

# Code coverage (optional, controlled by environment variable)
if ENV["COVERAGE"]
  require "simplecov"
  SimpleCov.start do
    add_filter "/spec/"
    add_filter "/vendor/"
    minimum_coverage 75
  end
end

require "gbln"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  # Use expect syntax
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Random order
  config.order = :random
  Kernel.srand config.seed

  # Shared test fixtures directory
  config.add_setting :fixtures_dir
  config.fixtures_dir = File.join(__dir__, "fixtures")

  # Helper method to load test fixtures
  config.include Module.new {
    def fixture_path(filename)
      File.join(RSpec.configuration.fixtures_dir, filename)
    end

    def load_fixture(filename)
      File.read(fixture_path(filename), encoding: "utf-8")
    end
  }
end
