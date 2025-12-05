# Copyright (c) 2025 Vivian Burkhard Voss
# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

require "ffi"

# GBLN (Goblin Bounded Lean Notation) - Ruby Bindings
#
# GBLN is a type-safe, memory-efficient serialisation format designed for
# LLM optimisation. It provides parse-time type validation, uses 86% fewer
# tokens than JSON in AI contexts, and is human-readable and git-friendly.
#
# @example Parsing GBLN
#   data = GBLN.parse('user{id<u32>(12345)name<s64>(Alice)}')
#   puts data["user"]["id"]  # => 12345
#
# @example Serialising to GBLN
#   data = { user: { id: 12345, name: "Alice" } }
#   gbln_string = GBLN.to_string(data)
#
# @example Reading from file
#   data = GBLN.parse_file("config.gbln")
#
# @example Writing to compressed I/O file
#   GBLN.write_io(data, "data.io.gbln.xz")
#
# @see https://gbln.dev
module GBLN
  # Load all GBLN modules in dependency order
  require_relative "gbln/version"
  require_relative "gbln/errors"
  require_relative "gbln/ffi_wrapper"
  require_relative "gbln/value_conversion"
  require_relative "gbln/config"
  require_relative "gbln/parser"
  require_relative "gbln/serialiser"
  require_relative "gbln/io"

  # Parse a GBLN string into Ruby data structures
  #
  # @param gbln_string [String] GBLN content to parse
  # @return [Object] Parsed data as Ruby Hash/Array/primitives
  # @raise [GBLN::ParseError] If parsing fails
  # @raise [GBLN::ValidationError] If type validation fails
  #
  # @example
  #   data = GBLN.parse('user{id<u32>(12345)name<s64>(Alice)}')
  #   puts data["user"]["name"]  # => "Alice"
  def self.parse(gbln_string)
    Parser.parse(gbln_string)
  end

  # Parse a GBLN file into Ruby data structures
  #
  # @param path [String] Path to GBLN file
  # @return [Object] Parsed data as Ruby Hash/Array/primitives
  # @raise [GBLN::IOError] If file cannot be read
  # @raise [GBLN::ParseError] If parsing fails
  # @raise [GBLN::ValidationError] If type validation fails
  #
  # @example
  #   data = GBLN.parse_file("config.gbln")
  def self.parse_file(path)
    Parser.parse_file(path)
  end

  # Serialise Ruby data to GBLN string
  #
  # @param value [Object] Ruby data to serialise (Hash, Array, primitives)
  # @param mini [Boolean] Whether to use mini mode (compact, no whitespace)
  # @return [String] GBLN string
  # @raise [GBLN::SerialiseError] If serialisation fails
  #
  # @example Mini mode (compact)
  #   gbln = GBLN.to_string({ user: { id: 12345 } }, mini: true)
  #   # => "user{id<u32>(12345)}"
  #
  # @example Pretty mode (with whitespace)
  #   gbln = GBLN.to_string({ user: { id: 12345 } }, mini: false)
  def self.to_string(value, mini: true)
    Serialiser.to_string(value, mini: mini)
  end

  # Serialise Ruby data to pretty-printed GBLN string
  #
  # @param value [Object] Ruby data to serialise
  # @param indent [Integer] Number of spaces for indentation (default: 2)
  # @return [String] Pretty-printed GBLN string
  # @raise [GBLN::SerialiseError] If serialisation fails
  #
  # @example
  #   gbln = GBLN.to_string_pretty({ user: { id: 12345, name: "Alice" } })
  def self.to_string_pretty(value, indent: 2)
    Serialiser.to_string_pretty(value, indent: indent)
  end

  # Read and parse a GBLN I/O file (.io.gbln.xz)
  #
  # @param path [String] Path to .io.gbln.xz file
  # @return [Object] Parsed data as Ruby Hash/Array/primitives
  # @raise [GBLN::IOError] If file cannot be read or decompressed
  # @raise [GBLN::ParseError] If parsing fails
  #
  # @example
  #   data = GBLN.read_io("data.io.gbln.xz")
  def self.read_io(path)
    IO.read_io(path)
  end

  # Write Ruby data to a GBLN I/O file (.io.gbln.xz)
  #
  # @param value [Object] Ruby data to serialise
  # @param path [String] Destination path for .io.gbln.xz file
  # @param config [GBLN::Config, nil] Configuration (defaults to Config.io_default)
  # @return [void]
  # @raise [GBLN::IOError] If file cannot be written
  # @raise [GBLN::SerialiseError] If serialisation fails
  #
  # @example With default configuration
  #   GBLN.write_io({ user: { id: 12345 } }, "data.io.gbln.xz")
  #
  # @example With custom configuration
  #   config = GBLN::Config.new(compression_level: 9)
  #   GBLN.write_io(data, "data.io.gbln.xz", config)
  def self.write_io(value, path, config = nil)
    IO.write_io(value, path, config)
  end

  # Get the GBLN library version
  #
  # @return [String] Version string (e.g., "0.9.0")
  #
  # @example
  #   puts GBLN.version  # => "0.9.0"
  def self.version
    VERSION
  end
end
