# Copyright (c) 2025 Vivian Burkhard Voss
# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

module GBLN
  # Base error for all GBLN errors.
  #
  # All GBLN-specific exceptions inherit from this class,
  # allowing users to catch all GBLN errors with a single rescue clause.
  #
  # @example Catching all GBLN errors
  #   begin
  #     GBLN.parse(invalid_input)
  #   rescue GBLN::Error => e
  #     puts "GBLN error: #{e.message}"
  #   end
  class Error < StandardError; end

  # Raised when parsing fails due to invalid syntax or structure.
  #
  # This includes:
  # - Syntax errors (missing braces, invalid tokens)
  # - Type mismatches
  # - Out-of-range values
  # - Duplicate keys
  #
  # @example
  #   GBLN.parse("invalid{")  # => ParseError: Unexpected EOF
  class ParseError < Error; end

  # Raised when validation fails.
  #
  # This includes:
  # - Configuration validation errors
  # - Value constraint violations
  #
  # @example
  #   GBLN::Config.new(compression_level: 99)  # => ValidationError: Invalid compression level
  class ValidationError < Error; end

  # Raised when I/O operations fail.
  #
  # This includes:
  # - File not found
  # - Permission denied
  # - Disk full
  # - Invalid paths
  #
  # @example
  #   GBLN.read_io("/nonexistent/file.io.gbln.xz")  # => IOError: File not found
  class IOError < Error; end

  # Raised when serialisation fails.
  #
  # This includes:
  # - Unsupported value types
  # - Values too large for GBLN types
  # - Circular references
  #
  # @example
  #   GBLN.to_string(Object.new)  # => SerialiseError: Unsupported type: Object
  class SerialiseError < Error; end
end
