# Copyright (c) 2025 Vivian Burkhard Voss
# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

module GBLN
  # I/O operations for reading and writing .io.gbln.xz files
  #
  # This module provides high-level I/O operations for GBLN data files
  # with automatic compression using XZ (LZMA2). The .io.gbln.xz format
  # is optimised for disk storage and network transfer.
  #
  # @example Reading a GBLN I/O file
  #   data = GBLN::IO.read_io("data.io.gbln.xz")
  #   puts data["user"]["name"]
  #
  # @example Writing a GBLN I/O file with custom configuration
  #   config = GBLN::Config.new(compression_level: 9)
  #   GBLN::IO.write_io({ user: { name: "Alice" } }, "data.io.gbln.xz", config)
  module IO
    # Read and parse a GBLN I/O file (.io.gbln.xz)
    #
    # Reads a compressed GBLN file, automatically decompresses it,
    # and parses the content into Ruby data structures.
    #
    # @param path [String] Path to the .io.gbln.xz file
    # @return [Object] Parsed GBLN data as Ruby Hash/Array/primitives
    # @raise [GBLN::IOError] If file cannot be read or decompressed
    # @raise [GBLN::ParseError] If GBLN content is invalid
    #
    # @example
    #   data = GBLN::IO.read_io("config.io.gbln.xz")
    #   puts data["app"]["version"]
    def self.read_io(path)
      raise ArgumentError, "Path cannot be nil" if path.nil?
      raise ArgumentError, "Path must be a String" unless path.is_a?(String)

      unless File.exist?(path)
        raise GBLN::IOError, "File does not exist: #{path}"
      end

      if File.directory?(path)
        raise GBLN::IOError, "Path is a directory: #{path}"
      end

      # Ensure path is absolute for FFI
      absolute_path = File.absolute_path(path)

      # Create output pointer for the parsed value
      value_out = ::FFI::MemoryPointer.new(:pointer)

      # Call C FFI function
      error_code = FFI.gbln_read_io(absolute_path, value_out)

      # Check for errors
      unless error_code == :ok
        error_message = extract_last_error
        case error_code
        when :io_error
          raise GBLN::IOError, "Failed to read file: #{error_message}"
        when :parse_error
          raise GBLN::ParseError, "Failed to parse GBLN content: #{error_message}"
        when :validation_error
          raise GBLN::ValidationError, "Validation failed: #{error_message}"
        else
          raise GBLN::Error, "Unknown error (#{error_code}): #{error_message}"
        end
      end

      # Extract the value pointer and wrap in AutoPointer for automatic cleanup
      value_ptr = value_out.read_pointer
      raise GBLN::IOError, "C function returned null value" if value_ptr.null?

      auto_ptr = ::FFI::AutoPointer.new(value_ptr, FFI.method(:gbln_value_free))

      # Convert to Ruby and return
      ValueConversion.to_ruby(auto_ptr)
    end

    # Write Ruby data to a GBLN I/O file (.io.gbln.xz)
    #
    # Serialises Ruby data structures to GBLN format, compresses
    # with XZ (LZMA2), and writes to disk.
    #
    # @param value [Object] Ruby data to serialise (Hash, Array, primitives)
    # @param path [String] Destination path for .io.gbln.xz file
    # @param config [GBLN::Config, nil] Configuration for serialisation and compression
    #   (defaults to Config.io_default if nil)
    # @return [void]
    # @raise [GBLN::IOError] If file cannot be written or compressed
    # @raise [GBLN::SerialiseError] If value cannot be serialised
    #
    # @example With default configuration
    #   data = { user: { id: 12345, name: "Alice" } }
    #   GBLN::IO.write_io(data, "user.io.gbln.xz")
    #
    # @example With custom configuration
    #   config = GBLN::Config.new(compression_level: 9, mini_mode: false)
    #   GBLN::IO.write_io(data, "user.io.gbln.xz", config)
    def self.write_io(value, path, config = nil)
      raise ArgumentError, "Value cannot be nil" if value.nil?
      raise ArgumentError, "Path cannot be nil" if path.nil?
      raise ArgumentError, "Path must be a String" unless path.is_a?(String)

      # Use default I/O configuration if none provided
      config ||= Config.io_default
      raise ArgumentError, "Config must be a GBLN::Config" unless config.is_a?(Config)

      # Validate configuration
      config.validate

      # Ensure path is absolute for FFI
      absolute_path = File.absolute_path(path)

      # Ensure parent directory exists
      parent_dir = File.dirname(absolute_path)
      unless File.directory?(parent_dir)
        raise GBLN::IOError, "Parent directory does not exist: #{parent_dir}"
      end

      # Convert Ruby value to C GBLN value
      c_value = ValueConversion.to_c(value)
      auto_value = ::FFI::AutoPointer.new(c_value, FFI.method(:gbln_value_free))

      # Create C config structure
      c_config = create_c_config(config)
      auto_config = ::FFI::AutoPointer.new(c_config, FFI.method(:gbln_config_free))

      # Call C FFI function
      error_code = FFI.gbln_write_io(auto_value, absolute_path, auto_config)

      # Check for errors
      unless error_code == :ok
        error_message = extract_last_error
        case error_code
        when :io_error
          raise GBLN::IOError, "Failed to write file: #{error_message}"
        when :serialise_error
          raise GBLN::SerialiseError, "Failed to serialise value: #{error_message}"
        when :validation_error
          raise GBLN::ValidationError, "Validation failed: #{error_message}"
        else
          raise GBLN::Error, "Unknown error (#{error_code}): #{error_message}"
        end
      end

      nil
    end

    # Extract the last error message from the C library
    #
    # @return [String] Error message or default message if unavailable
    # @api private
    def self.extract_last_error
      error_ptr = FFI.gbln_last_error
      return "Unknown error" if error_ptr.null?

      error_ptr.read_string
    rescue StandardError
      "Unknown error"
    end
    private_class_method :extract_last_error

    # Create a C config structure from Ruby Config object
    #
    # @param config [GBLN::Config] Ruby configuration object
    # @return [FFI::Pointer] Pointer to C config structure
    # @raise [GBLN::Error] If config creation fails
    # @api private
    def self.create_c_config(config)
      c_config = FFI.gbln_config_new(
        config.mini_mode,
        config.compress,
        config.compression_level,
        config.indent,
        config.strip_comments
      )

      raise GBLN::Error, "Failed to create C config structure" if c_config.null?

      c_config
    rescue StandardError => e
      # Clean up on error
      FFI.gbln_config_free(c_config) unless c_config.nil? || c_config.null?
      raise GBLN::Error, "Failed to configure C config: #{e.message}"
    end
    private_class_method :create_c_config
  end
end
