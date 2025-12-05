# frozen_string_literal: true

require_relative "lib/gbln/version"

Gem::Specification.new do |spec|
  spec.name = "gbln"
  spec.version = GBLN::VERSION
  spec.authors = ["Vivian Burkhard Voss"]
  spec.email = ["ask@vvoss.dev"]

  spec.summary = "GBLN (Goblin Bounded Lean Notation) - Type-safe, LLM-optimised serialisation format"
  spec.description = <<~DESC
    GBLN is a type-safe, memory-efficient serialisation format designed for LLM optimisation.
    It provides parse-time type validation, uses 86% fewer tokens than JSON in AI contexts,
    and is human-readable and git-friendly. This gem provides Ruby bindings to the native
    GBLN parser via FFI.
  DESC
  spec.homepage = "https://gbln.dev"
  spec.license = "Apache-2.0"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata = {
    "homepage_uri" => spec.homepage,
    "source_code_uri" => "https://github.com/gbln-org/gbln-ruby",
    "bug_tracker_uri" => "https://github.com/gbln-org/gbln-ruby/issues",
    "documentation_uri" => "https://gbln.dev/docs/ruby",
    "changelog_uri" => "https://github.com/gbln-org/gbln-ruby/blob/main/CHANGELOG.md"
  }

  # Specify which files should be added to the gem when it is released
  spec.files = Dir[
    "lib/**/*.rb",
    "LICENSE",
    "README.md",
    "CHANGELOG.md"
  ]
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "ffi", "~> 1.15"

  # Development dependencies
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "yard", "~> 0.9"
  spec.add_development_dependency "rubocop", "~> 1.50"
  spec.add_development_dependency "simplecov", "~> 0.22"

  # Platform-specific notes
  spec.post_install_message = <<~MSG

    ===============================================================================
    GBLN Ruby Bindings v#{GBLN::VERSION} installed successfully!

    This gem requires the GBLN C library (libgbln) to be available.

    Platform-specific library locations:
    - macOS (ARM64):   core/ffi/libs/aarch64-apple-darwin/libgbln.dylib
    - macOS (x64):     core/ffi/libs/x86_64-apple-darwin/libgbln.dylib
    - Linux (x64):     core/ffi/libs/x86_64-unknown-linux-gnu/libgbln.so
    - Linux (ARM64):   core/ffi/libs/aarch64-unknown-linux-gnu/libgbln.so
    - Windows (x64):   core/ffi/libs/x86_64-pc-windows-gnu/gbln.dll

    The library will be automatically located if:
    1. GBLN_LIB_PATH environment variable is set, OR
    2. Library is bundled with the gem, OR
    3. Library is in the GBLN development tree, OR
    4. Library is in system library paths

    Documentation: https://gbln.dev/docs/ruby
    Examples: https://github.com/gbln-org/gbln-ruby/tree/main/examples

    ===============================================================================

  MSG
end
