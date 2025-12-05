# Copyright (c) 2025 Vivian Burkhard Voss
# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

module GBLN
  # Parse GBLN strings and files.
  #
  # Provides high-level parsing API with automatic memory management
  # and detailed error messages.
  #
  # @example Parse GBLN string
  #   data = GBLN::Parser.parse("user{id<u32>(123)name<s64>(Alice)}")
  #   data["user"]["name"]  # => "Alice"
  #
  # @example Parse GBLN file
  #   data = GBLN::Parser.parse_file("config.gbln")
  module Parser
    # Parse GBLN string to Ruby value.
    #
    # @param gbln_string [String] GBLN-formatted string
    # @return [Hash, Array, Integer, Float, String, true, false, nil] Parsed value
    # @raise [ArgumentError] if input not a String
    # @raise [ParseError] if parsing fails
    #
    # @example Parse object
    #   data = GBLN::Parser.parse("user{id<u32>(123)}")
    #   data["user"]["id"]  # => 123
    #
    # @example Parse array
    #   data = GBLN::Parser.parse("tags<s16>[rust python golang]")
    #   data["tags"]  # => ["rust", "python", "golang"]
    def self.parse(gbln_string)
      raise ArgumentError, "Input must be a String" unless gbln_string.is_a?(String)

      out_value_ptr = ::FFI::MemoryPointer.new(:pointer)
      result = FFI.gbln_parse(gbln_string, out_value_ptr)

      unless result == :ok
        error_msg = FFI.gbln_last_error_message
        raise ParseError, error_msg || "Parse failed with code: #{result}"
      end

      value_ptr = out_value_ptr.read_pointer
      raise ParseError, "Parse returned null pointer" if value_ptr.null?

      # Convert C value to Ruby with automatic cleanup
      auto_ptr = ::FFI::AutoPointer.new(value_ptr, FFI.method(:gbln_value_free))
      ValueConversion.to_ruby(auto_ptr)
    end

    # Parse GBLN file to Ruby value.
    #
    # Reads file content and parses it. Handles UTF-8 encoding automatically.
    #
    # @param path [String, Pathname] Path to .gbln file
    # @return [Hash, Array, Integer, Float, String, true, false, nil] Parsed value
    # @raise [ArgumentError] if path not a String or Pathname
    # @raise [IOError] if file cannot be read
    # @raise [ParseError] if parsing fails
    #
    # @example Parse configuration file
    #   config = GBLN::Parser.parse_file("app.gbln")
    #   config["app"]["port"]  # => 8080
    def self.parse_file(path)
      path_str = path.to_s
      raise ArgumentError, "Path must be a String or Pathname" if path_str.empty?
      raise IOError, "File not found: #{path_str}" unless File.exist?(path_str)
      raise IOError, "Path is a directory: #{path_str}" if File.directory?(path_str)

      # Read file with UTF-8 encoding
      content = File.read(path_str, encoding: "UTF-8")
      parse(content)
    rescue Errno::ENOENT => e
      raise IOError, "File not found: #{path_str} (#{e.message})"
    rescue Errno::EACCES => e
      raise IOError, "Permission denied: #{path_str} (#{e.message})"
    rescue Errno::EISDIR => e
      raise IOError, "Path is a directory: #{path_str} (#{e.message})"
    rescue SystemCallError => e
      raise IOError, "Cannot read file #{path_str}: #{e.message}"
    end
  end
end
