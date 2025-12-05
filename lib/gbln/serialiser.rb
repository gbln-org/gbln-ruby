# Copyright (c) 2025 Vivian Burkhard Voss
# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

module GBLN
  # Serialise Ruby values to GBLN strings.
  #
  # Provides high-level serialisation API with automatic memory management
  # and type selection.
  #
  # @example Convert to GBLN string
  #   data = { "user" => { "id" => 123, "name" => "Alice" } }
  #   gbln_str = GBLN::Serialiser.to_string(data)
  #   # => "{user{id<u8>(123)name<s8>(Alice)}}"
  #
  # @example Pretty printing
  #   pretty = GBLN::Serialiser.to_string_pretty(data, indent: 2)
  module Serialiser
    # Convert Ruby value to GBLN string.
    #
    # Uses MINI format (compact, no whitespace) by default.
    # Automatically selects optimal GBLN types for integers and strings.
    #
    # @param value [Hash, Array, Integer, Float, String, true, false, nil] Ruby value
    # @param mini [Boolean] Use MINI format (default: true)
    # @return [String] GBLN-formatted string
    # @raise [SerialiseError] if serialisation fails
    #
    # @example Compact format
    #   GBLN::Serialiser.to_string({ "id" => 42 }, mini: true)
    #   # => "{id<u8>(42)}"
    #
    # @example Pretty format
    #   GBLN::Serialiser.to_string({ "id" => 42 }, mini: false)
    #   # => "{\n  id<u8>(42)\n}"
    def self.to_string(value, mini: true)
      c_value = ValueConversion.to_c(value)
      auto_ptr = ::FFI::AutoPointer.new(c_value, FFI.method(:gbln_value_free))

      result = if mini
                 FFI.gbln_to_string(auto_ptr)
               else
                 FFI.gbln_to_string_pretty(auto_ptr)
               end

      raise SerialiseError, "Serialisation returned null" if result.nil?
      result
    end

    # Convert Ruby value to pretty GBLN string.
    #
    # Adds whitespace and indentation for human readability.
    #
    # @param value [Hash, Array, Integer, Float, String, true, false, nil] Ruby value
    # @param indent [Integer] Indentation width (default: 2)
    # @return [String] GBLN-formatted string with whitespace
    # @raise [ArgumentError] if indent not positive
    # @raise [SerialiseError] if serialisation fails
    #
    # @example
    #   data = {
    #     "user" => {
    #       "id" => 123,
    #       "name" => "Alice",
    #       "tags" => ["rust", "python"]
    #     }
    #   }
    #   puts GBLN::Serialiser.to_string_pretty(data)
    #   # {
    #   #   user{
    #   #     id<u8>(123)
    #   #     name<s8>(Alice)
    #   #     tags<s8>[rust python]
    #   #   }
    #   # }
    def self.to_string_pretty(value, indent: 2)
      raise ArgumentError, "Indent must be positive" unless indent.is_a?(Integer) && indent.positive?

      # Note: Current C FFI uses fixed indentation (2 spaces)
      # The indent parameter is accepted for API consistency but not yet configurable
      to_string(value, mini: false)
    end
  end
end
