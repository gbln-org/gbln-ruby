# Copyright (c) 2025 Vivian Burkhard Voss
# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

module GBLN
  # Bidirectional conversion between Ruby and C FFI values.
  #
  # Handles conversion of GBLN values to Ruby types and vice versa,
  # including automatic type selection for integers and strings.
  #
  # @api private
  module ValueConversion
    # Convert C GblnValue to Ruby value.
    #
    # Uses type introspection to determine the correct conversion method.
    # Recursively handles objects and arrays.
    #
    # @param value_ptr [FFI::Pointer] Pointer to GblnValue
    # @return [Hash, Array, Integer, Float, String, true, false, nil]
    # @raise [Error] if unknown type encountered
    def self.to_ruby(value_ptr)
      return nil if value_ptr.null?

      type = FFI.gbln_value_type(value_ptr)

      case type
      when :null
        nil
      when :bool
        ok_ptr = ::FFI::MemoryPointer.new(:bool)
        result = FFI.gbln_value_as_bool(value_ptr, ok_ptr)
        raise ParseError, "Failed to extract boolean" unless ok_ptr.read_char != 0
        result
      when :i8
        extract_integer(:gbln_value_as_i8, value_ptr, "i8")
      when :i16
        extract_integer(:gbln_value_as_i16, value_ptr, "i16")
      when :i32
        extract_integer(:gbln_value_as_i32, value_ptr, "i32")
      when :i64
        extract_integer(:gbln_value_as_i64, value_ptr, "i64")
      when :u8
        extract_integer(:gbln_value_as_u8, value_ptr, "u8")
      when :u16
        extract_integer(:gbln_value_as_u16, value_ptr, "u16")
      when :u32
        extract_integer(:gbln_value_as_u32, value_ptr, "u32")
      when :u64
        extract_integer(:gbln_value_as_u64, value_ptr, "u64")
      when :f32
        extract_float(:gbln_value_as_f32, value_ptr, "f32")
      when :f64
        extract_float(:gbln_value_as_f64, value_ptr, "f64")
      when :str
        extract_string(value_ptr)
      when :object
        convert_object(value_ptr)
      when :array
        convert_array(value_ptr)
      else
        raise Error, "Unknown type: #{type}"
      end
    end

    # Convert Ruby value to C GblnValue.
    #
    # Uses automatic type selection for integers and strings.
    # Recursively handles hashes and arrays.
    #
    # @param value [Hash, Array, Integer, Float, String, true, false, nil]
    # @return [FFI::Pointer] Pointer to GblnValue (caller owns)
    # @raise [SerialiseError] if unsupported type
    def self.to_c(value)
      case value
      when nil
        FFI.gbln_value_new_null
      when TrueClass, FalseClass
        FFI.gbln_value_new_bool(value)
      when Integer
        create_optimal_integer(value)
      when Float
        FFI.gbln_value_new_f64(value)
      when String
        create_optimal_string(value)
      when Hash
        create_object(value)
      when Array
        create_array(value)
      else
        raise SerialiseError, "Unsupported type: #{value.class}"
      end
    end

    # Extract integer value from C pointer.
    #
    # @param method [Symbol] FFI method name
    # @param value_ptr [FFI::Pointer] Pointer to GblnValue
    # @param type_name [String] Type name for error messages
    # @return [Integer]
    # @raise [ParseError] if extraction fails
    # @api private
    def self.extract_integer(method, value_ptr, type_name)
      ok_ptr = ::FFI::MemoryPointer.new(:bool)
      result = FFI.send(method, value_ptr, ok_ptr)
      raise ParseError, "Failed to extract #{type_name}" unless ok_ptr.read_char != 0
      result
    end
    private_class_method :extract_integer

    # Extract float value from C pointer.
    #
    # @param method [Symbol] FFI method name
    # @param value_ptr [FFI::Pointer] Pointer to GblnValue
    # @param type_name [String] Type name for error messages
    # @return [Float]
    # @raise [ParseError] if extraction fails
    # @api private
    def self.extract_float(method, value_ptr, type_name)
      ok_ptr = ::FFI::MemoryPointer.new(:bool)
      result = FFI.send(method, value_ptr, ok_ptr)
      raise ParseError, "Failed to extract #{type_name}" unless ok_ptr.read_char != 0
      result
    end
    private_class_method :extract_float

    # Extract string value from C pointer.
    #
    # @param value_ptr [FFI::Pointer] Pointer to GblnValue
    # @return [String]
    # @raise [ParseError] if extraction fails
    # @api private
    def self.extract_string(value_ptr)
      ok_ptr = ::FFI::MemoryPointer.new(:bool)
      result = FFI.gbln_value_as_string(value_ptr, ok_ptr)
      raise ParseError, "Failed to extract string" unless ok_ptr.read_char != 0
      raise ParseError, "String extraction returned nil" if result.nil?
      result
    end
    private_class_method :extract_string

    # Convert C Object to Ruby Hash.
    #
    # Uses gbln_object_keys to iterate over all keys,
    # then recursively converts each value.
    #
    # @param value_ptr [FFI::Pointer] Pointer to GblnValue (Object)
    # @return [Hash]
    # @raise [ParseError] if conversion fails
    # @api private
    def self.convert_object(value_ptr)
      len = FFI.gbln_object_len(value_ptr)
      result = {}

      return result if len.zero?

      # Get all keys
      count_ptr = ::FFI::MemoryPointer.new(:size_t)
      keys_ptr = FFI.gbln_object_keys(value_ptr, count_ptr)
      count = count_ptr.read(:size_t)

      raise ParseError, "Failed to get object keys" if keys_ptr.null? && count > 0

      # Convert keys array to Ruby strings
      keys = keys_ptr.read_array_of_pointer(count).map(&:read_string)

      # Get value for each key
      keys.each do |key|
        child_ptr = FFI.gbln_object_get(value_ptr, key)
        raise ParseError, "Failed to get value for key: #{key}" if child_ptr.null?
        result[key] = to_ruby(child_ptr)
      end

      # Free keys array
      FFI.gbln_keys_free(keys_ptr, count)

      result
    end
    private_class_method :convert_object

    # Convert C Array to Ruby Array.
    #
    # Iterates over array elements and recursively converts each.
    #
    # @param value_ptr [FFI::Pointer] Pointer to GblnValue (Array)
    # @return [Array]
    # @raise [ParseError] if conversion fails
    # @api private
    def self.convert_array(value_ptr)
      len = FFI.gbln_array_len(value_ptr)
      result = []

      len.times do |i|
        child_ptr = FFI.gbln_array_get(value_ptr, i)
        raise ParseError, "Failed to get array element at index #{i}" if child_ptr.null?
        result << to_ruby(child_ptr)
      end

      result
    end
    private_class_method :convert_array

    # Create optimal GBLN integer type from Ruby Integer.
    #
    # Selects the smallest type that fits the value:
    # - Unsigned types (u8-u64) for non-negative values
    # - Signed types (i8-i64) for negative values
    #
    # @param value [Integer]
    # @return [FFI::Pointer] Pointer to GblnValue
    # @api private
    def self.create_optimal_integer(value)
      # Try unsigned types first for non-negative values
      if value >= 0
        return FFI.gbln_value_new_u8(value) if value <= 255
        return FFI.gbln_value_new_u16(value) if value <= 65_535
        return FFI.gbln_value_new_u32(value) if value <= 4_294_967_295
        return FFI.gbln_value_new_u64(value) if value <= 18_446_744_073_709_551_615
      end

      # Signed types for negative values or very large positive
      return FFI.gbln_value_new_i8(value) if value >= -128 && value <= 127
      return FFI.gbln_value_new_i16(value) if value >= -32_768 && value <= 32_767
      return FFI.gbln_value_new_i32(value) if value >= -2_147_483_648 && value <= 2_147_483_647
      return FFI.gbln_value_new_i64(value) if value >= -9_223_372_036_854_775_808 && value <= 9_223_372_036_854_775_807

      raise SerialiseError, "Integer out of range: #{value}"
    end
    private_class_method :create_optimal_integer

    # Create optimal GBLN string type from Ruby String.
    #
    # Selects string type based on UTF-8 character count:
    # - s64 for ≤64 characters
    # - s256 for ≤256 characters
    # - s1024 for ≤1024 characters
    #
    # @param value [String]
    # @return [FFI::Pointer] Pointer to GblnValue
    # @raise [SerialiseError] if string too long
    # @api private
    def self.create_optimal_string(value)
      # Count UTF-8 characters (not bytes)
      char_count = value.chars.length

      max_len = if char_count <= 2
                  2
                elsif char_count <= 4
                  4
                elsif char_count <= 8
                  8
                elsif char_count <= 16
                  16
                elsif char_count <= 32
                  32
                elsif char_count <= 64
                  64
                elsif char_count <= 128
                  128
                elsif char_count <= 256
                  256
                elsif char_count <= 512
                  512
                elsif char_count <= 1024
                  1024
                else
                  raise SerialiseError, "String too long: #{char_count} characters (max 1024)"
                end

      FFI.gbln_value_new_str(value, max_len)
    end
    private_class_method :create_optimal_string

    # Create C Object from Ruby Hash.
    #
    # Converts each key-value pair recursively and builds GBLN object.
    #
    # @param hash [Hash]
    # @return [FFI::Pointer] Pointer to GblnValue (Object)
    # @raise [SerialiseError] if conversion fails
    # @api private
    def self.create_object(hash)
      obj_ptr = FFI.gbln_value_new_object
      raise SerialiseError, "Failed to create object" if obj_ptr.null?

      hash.each do |key, value|
        child_ptr = to_c(value)
        result = FFI.gbln_object_insert(obj_ptr, key.to_s, child_ptr)

        if result != :ok
          # On error, ownership not transferred - must free both
          FFI.gbln_value_free(child_ptr)
          FFI.gbln_value_free(obj_ptr)
          raise SerialiseError, "Failed to insert key: #{key}"
        end
        # On success, obj_ptr owns child_ptr - don't free child_ptr
      end

      obj_ptr
    end
    private_class_method :create_object

    # Create C Array from Ruby Array.
    #
    # Converts each element recursively and builds GBLN array.
    #
    # @param array [Array]
    # @return [FFI::Pointer] Pointer to GblnValue (Array)
    # @raise [SerialiseError] if conversion fails
    # @api private
    def self.create_array(array)
      arr_ptr = FFI.gbln_value_new_array
      raise SerialiseError, "Failed to create array" if arr_ptr.null?

      array.each do |value|
        child_ptr = to_c(value)
        result = FFI.gbln_array_push(arr_ptr, child_ptr)

        if result != :ok
          # On error, ownership not transferred - must free both
          FFI.gbln_value_free(child_ptr)
          FFI.gbln_value_free(arr_ptr)
          raise SerialiseError, "Failed to push array element"
        end
        # On success, arr_ptr owns child_ptr - don't free child_ptr
      end

      arr_ptr
    end
    private_class_method :create_array
  end
end
