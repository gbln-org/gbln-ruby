# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rubocop/rake_task"

# Default task runs tests
task default: %i[spec rubocop]

# RSpec test suite
RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = "--format documentation --color"
end

# RuboCop code quality checks
RuboCop::RakeTask.new(:rubocop) do |t|
  t.options = ["--display-cop-names"]
end

# RuboCop auto-correct
RuboCop::RakeTask.new("rubocop:autocorrect") do |t|
  t.options = ["--autocorrect"]
end

# YARD documentation generation
begin
  require "yard"

  YARD::Rake::YardocTask.new(:yard) do |t|
    t.files = ["lib/**/*.rb"]
    t.options = ["--output-dir", "doc", "--readme", "README.md"]
  end
rescue LoadError
  # YARD not available
  task :yard do
    warn "YARD is not available. Install with: gem install yard"
  end
end

# Code coverage
namespace :spec do
  desc "Run tests with code coverage"
  task :coverage do
    ENV["COVERAGE"] = "true"
    Rake::Task["spec"].execute
  end
end

# Build native library (for development)
namespace :build do
  desc "Build GBLN C library for current platform"
  task :native do
    puts "Building GBLN C library..."

    # Determine platform
    require "rbconfig"
    os = RbConfig::CONFIG["host_os"]
    arch = RbConfig::CONFIG["host_cpu"]

    platform = case os
               when /darwin/
                 case arch
                 when /arm64|aarch64/ then "aarch64-apple-darwin"
                 when /x86_64/ then "x86_64-apple-darwin"
                 else
                   raise "Unsupported macOS architecture: #{arch}"
                 end
               when /linux/
                 case arch
                 when /x86_64/ then "x86_64-unknown-linux-gnu"
                 when /aarch64|arm64/ then "aarch64-unknown-linux-gnu"
                 else
                   raise "Unsupported Linux architecture: #{arch}"
                 end
               when /freebsd/
                 case arch
                 when /x86_64/ then "x86_64-unknown-freebsd"
                 when /aarch64|arm64/ then "aarch64-unknown-freebsd"
                 else
                   raise "Unsupported FreeBSD architecture: #{arch}"
                 end
               when /mingw|mswin/
                 "x86_64-pc-windows-gnu"
               else
                 raise "Unsupported operating system: #{os}"
               end

    puts "Detected platform: #{platform}"

    # Check if we're in the GBLN development tree
    project_root = File.expand_path("../..", __dir__)
    c_ffi_path = File.join(project_root, "core", "c")

    unless File.directory?(c_ffi_path)
      warn "GBLN C FFI source not found at: #{c_ffi_path}"
      warn "This task requires the full GBLN development tree."
      exit 1
    end

    # Build using cross
    Dir.chdir(c_ffi_path) do
      sh "cross build --release --target #{platform.gsub('-unknown', '-')}"
    end

    puts "Build complete! Library location:"
    puts "  #{project_root}/core/ffi/libs/#{platform}/"
  end

  desc "Build GBLN C library for all platforms"
  task :all do
    platforms = [
      "aarch64-apple-darwin",
      "x86_64-apple-darwin",
      "x86_64-unknown-linux-gnu",
      "aarch64-unknown-linux-gnu",
      "x86_64-unknown-freebsd",
      "aarch64-unknown-freebsd",
      "x86_64-pc-windows-gnu",
      "aarch64-linux-android",
      "x86_64-linux-android"
    ]

    project_root = File.expand_path("../..", __dir__)
    c_ffi_path = File.join(project_root, "core", "c")

    unless File.directory?(c_ffi_path)
      warn "GBLN C FFI source not found at: #{c_ffi_path}"
      warn "This task requires the full GBLN development tree."
      exit 1
    end

    platforms.each do |platform|
      puts "\n" + ("=" * 80)
      puts "Building for #{platform}..."
      puts "=" * 80

      Dir.chdir(c_ffi_path) do
        target = platform.gsub("-unknown", "-")
        sh "cross build --release --target #{target}"
      end
    end

    puts "\n" + ("=" * 80)
    puts "All builds complete!"
    puts "=" * 80
  end
end

# Clean build artifacts
desc "Clean build artifacts"
task :clean do
  FileUtils.rm_rf "pkg"
  FileUtils.rm_rf "doc"
  FileUtils.rm_rf "coverage"
  FileUtils.rm_f ".rspec_status"
  puts "Cleaned build artifacts"
end

# Information task
desc "Display gem information"
task :info do
  require_relative "lib/gbln/version"

  puts "GBLN Ruby Bindings"
  puts "Version: #{GBLN::VERSION}"
  puts "Ruby Version: #{RUBY_VERSION}"
  puts "Platform: #{RUBY_PLATFORM}"
  puts ""
  puts "Gem Specification:"
  puts "  Name: gbln"
  puts "  Homepage: https://gbln.dev"
  puts "  Source: https://github.com/gbln-org/gbln-ruby"
  puts "  License: Apache-2.0"
end
