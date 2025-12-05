# Copyright (c) 2025 Vivian Burkhard Voss
# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

require "ffi"
require "rbconfig"

module GBLN
  # FFI wrapper for libgbln C library.
  #
  # Provides Ruby bindings to the C FFI layer, handling:
  # - Platform detection and library loading
  # - C function declarations
  # - Memory management via FFI::AutoPointer
  #
  # @api private
  module FFI
    extend ::FFI::Library

    # Find and load the appropriate libgbln for the current platform.
    #
    # Search order:
    # 1. GBLN_LIBRARY_PATH environment variable
    # 2. Bundled library (gem installation)
    # 3. Relative path to core/ffi/libs/ (development)
    # 4. System library paths
    #
    # @return [String] path to library
    # @raise [LoadError] if library not found
    def self.find_library
      os = RbConfig::CONFIG["host_os"]
      arch = RbConfig::CONFIG["host_cpu"]

      # Determine library name and platform directory
      lib_name, platform_dir = case os
                                when /darwin|mac os/i
                                  case arch
                                  when /arm64|aarch64/i
                                    ["libgbln.dylib", "macos-arm64"]
                                  when /x86_64|amd64/i
                                    ["libgbln.dylib", "macos-x64"]
                                  else
                                    raise LoadError, "Unsupported macOS architecture: #{arch}"
                                  end
                                when /linux/i
                                  case arch
                                  when /x86_64|amd64/i
                                    ["libgbln.so", "linux-x64"]
                                  when /arm64|aarch64/i
                                    ["libgbln.so", "linux-arm64"]
                                  else
                                    raise LoadError, "Unsupported Linux architecture: #{arch}"
                                  end
                                when /freebsd/i
                                  case arch
                                  when /x86_64|amd64/i
                                    ["libgbln.so", "freebsd-x64"]
                                  when /arm64|aarch64/i
                                    ["libgbln.so", "freebsd-arm64"]
                                  else
                                    raise LoadError, "Unsupported FreeBSD architecture: #{arch}"
                                  end
                                when /mingw|mswin|windows/i
                                  ["gbln.dll", "windows-x64"]
                                else
                                  raise LoadError, "Unsupported platform: #{os}"
                                end

      # 1. Environment variable
      if ENV["GBLN_LIBRARY_PATH"] && File.exist?(ENV["GBLN_LIBRARY_PATH"])
        return ENV["GBLN_LIBRARY_PATH"]
      end

      # 2. Bundled library (gem installation)
      bundled = File.expand_path("../../../ext/precompiled/#{platform_dir}/#{lib_name}", __dir__)
      return bundled if File.exist?(bundled)

      # 3. Development path (../../core/ffi/libs/)
      dev_path = File.expand_path("../../../../core/ffi/libs/#{platform_dir}/#{lib_name}", __dir__)
      return dev_path if File.exist?(dev_path)

      # 4. System paths (try bare library name)
      lib_name
    end

    # Load the library
    ffi_lib find_library

    # Opaque pointer types
    typedef :pointer, :gbln_value_ptr
    typedef :pointer, :gbln_config_ptr

    # Error codes (from C FFI ticket #005)
    enum :gbln_error_code, [
      :ok, 0,
      :error_unexpected_char, 1,
      :error_unterminated_string, 2,
      :error_unexpected_token, 3,
      :error_unexpected_eof, 4,
      :error_invalid_syntax, 5,
      :error_int_out_of_range, 6,
      :error_string_too_long, 7,
      :error_type_mismatch, 8,
      :error_invalid_type_hint, 9,
      :error_duplicate_key, 10,
      :error_null_pointer, 11,
      :error_io, 12
    ]

    # Value type enum (from C FFI extensions ticket #005B)
    enum :gbln_value_type, [
      :i8, 0,
      :i16, 1,
      :i32, 2,
      :i64, 3,
      :u8, 4,
      :u16, 5,
      :u32, 6,
      :u64, 7,
      :f32, 8,
      :f64, 9,
      :str, 10,
      :bool, 11,
      :null, 12,
      :object, 13,
      :array, 14
    ]

    # Core parsing and serialisation functions
    attach_function :gbln_parse, [:string, :pointer], :gbln_error_code
    attach_function :gbln_to_string, [:gbln_value_ptr], :string
    attach_function :gbln_to_string_pretty, [:gbln_value_ptr], :string

    # Memory management
    attach_function :gbln_value_free, [:gbln_value_ptr], :void
    attach_function :gbln_string_free, [:pointer], :void
    attach_function :gbln_config_free, [:gbln_config_ptr], :void

    # Error information
    attach_function :gbln_last_error_message, [], :string

    # Type introspection (from ticket #005B)
    attach_function :gbln_value_type, [:gbln_value_ptr], :gbln_value_type

    # Value extraction functions (primitives)
    attach_function :gbln_value_as_i8, [:gbln_value_ptr, :pointer], :int8
    attach_function :gbln_value_as_i16, [:gbln_value_ptr, :pointer], :int16
    attach_function :gbln_value_as_i32, [:gbln_value_ptr, :pointer], :int32
    attach_function :gbln_value_as_i64, [:gbln_value_ptr, :pointer], :int64
    attach_function :gbln_value_as_u8, [:gbln_value_ptr, :pointer], :uint8
    attach_function :gbln_value_as_u16, [:gbln_value_ptr, :pointer], :uint16
    attach_function :gbln_value_as_u32, [:gbln_value_ptr, :pointer], :uint32
    attach_function :gbln_value_as_u64, [:gbln_value_ptr, :pointer], :uint64
    attach_function :gbln_value_as_f32, [:gbln_value_ptr, :pointer], :float
    attach_function :gbln_value_as_f64, [:gbln_value_ptr, :pointer], :double
    attach_function :gbln_value_as_bool, [:gbln_value_ptr, :pointer], :bool
    attach_function :gbln_value_as_string, [:gbln_value_ptr, :pointer], :string

    # Object functions
    attach_function :gbln_object_keys, [:gbln_value_ptr, :pointer], :pointer
    attach_function :gbln_object_len, [:gbln_value_ptr], :size_t
    attach_function :gbln_object_get, [:gbln_value_ptr, :string], :gbln_value_ptr
    attach_function :gbln_keys_free, [:pointer, :size_t], :void

    # Array functions
    attach_function :gbln_array_len, [:gbln_value_ptr], :size_t
    attach_function :gbln_array_get, [:gbln_value_ptr, :size_t], :gbln_value_ptr

    # Value constructors (from ticket #005B)
    attach_function :gbln_value_new_i8, [:int8], :gbln_value_ptr
    attach_function :gbln_value_new_i16, [:int16], :gbln_value_ptr
    attach_function :gbln_value_new_i32, [:int32], :gbln_value_ptr
    attach_function :gbln_value_new_i64, [:int64], :gbln_value_ptr
    attach_function :gbln_value_new_u8, [:uint8], :gbln_value_ptr
    attach_function :gbln_value_new_u16, [:uint16], :gbln_value_ptr
    attach_function :gbln_value_new_u32, [:uint32], :gbln_value_ptr
    attach_function :gbln_value_new_u64, [:uint64], :gbln_value_ptr
    attach_function :gbln_value_new_f32, [:float], :gbln_value_ptr
    attach_function :gbln_value_new_f64, [:double], :gbln_value_ptr
    attach_function :gbln_value_new_str, [:string, :size_t], :gbln_value_ptr
    attach_function :gbln_value_new_bool, [:bool], :gbln_value_ptr
    attach_function :gbln_value_new_null, [], :gbln_value_ptr

    # Complex type builders
    attach_function :gbln_value_new_object, [], :gbln_value_ptr
    attach_function :gbln_object_insert, [:gbln_value_ptr, :string, :gbln_value_ptr], :gbln_error_code
    attach_function :gbln_value_new_array, [], :gbln_value_ptr
    attach_function :gbln_array_push, [:gbln_value_ptr, :gbln_value_ptr], :gbln_error_code

    # I/O functions (from ticket #006)
    attach_function :gbln_config_new, [:bool, :bool, :uint8, :size_t, :bool], :gbln_config_ptr
    attach_function :gbln_write_io, [:gbln_value_ptr, :string, :gbln_config_ptr], :gbln_error_code
    attach_function :gbln_read_io, [:string, :pointer], :gbln_error_code

    # File I/O helper (parse file)
    attach_function :gbln_parse_file, [:string, :pointer], :gbln_error_code
  end
end
