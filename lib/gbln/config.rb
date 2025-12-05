# Copyright (c) 2025 Vivian Burkhard Voss
# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

module GBLN
  # Configuration for GBLN I/O operations.
  #
  # Controls serialisation format, compression, and output formatting.
  #
  # @example Default I/O configuration
  #   config = GBLN::Config.io_default
  #   config.mini_mode      # => true
  #   config.compress       # => true
  #   config.compress_level # => 6
  #
  # @example Source code configuration
  #   config = GBLN::Config.source_default
  #   config.mini_mode      # => false
  #   config.indent         # => 2
  #   config.strip_comments # => false
  class Config
    # Use MINI format (compact, no whitespace)
    # @return [Boolean]
    attr_accessor :mini_mode

    # Enable XZ compression for I/O format
    # @return [Boolean]
    attr_accessor :compress

    # XZ compression level (0-9, higher = better compression, slower)
    # @return [Integer]
    attr_accessor :compression_level

    # Indentation width for pretty printing
    # @return [Integer]
    attr_accessor :indent

    # Strip comments from output
    # @return [Boolean]
    attr_accessor :strip_comments

    # Create new configuration.
    #
    # @param mini_mode [Boolean] Use MINI format (default: true)
    # @param compress [Boolean] Enable compression (default: true)
    # @param compression_level [Integer] Compression level 0-9 (default: 6)
    # @param indent [Integer] Indentation width (default: 2)
    # @param strip_comments [Boolean] Strip comments (default: true)
    #
    # @raise [ValidationError] if parameters invalid
    def initialize(mini_mode: true, compress: true, compression_level: 6, indent: 2, strip_comments: true)
      @mini_mode = mini_mode
      @compress = compress
      @compression_level = compression_level
      @indent = indent
      @strip_comments = strip_comments

      validate
    end

    # Validate configuration parameters.
    #
    # @raise [ValidationError] if invalid
    # @return [void]
    def validate
      unless [true, false].include?(@mini_mode)
        raise ValidationError, "mini_mode must be boolean, got: #{@mini_mode.class}"
      end

      unless [true, false].include?(@compress)
        raise ValidationError, "compress must be boolean, got: #{@compress.class}"
      end

      unless @compression_level.is_a?(Integer) && @compression_level.between?(0, 9)
        raise ValidationError, "compression_level must be 0-9, got: #{@compression_level}"
      end

      unless @indent.is_a?(Integer) && @indent.positive?
        raise ValidationError, "indent must be positive integer, got: #{@indent}"
      end

      unless [true, false].include?(@strip_comments)
        raise ValidationError, "strip_comments must be boolean, got: #{@strip_comments.class}"
      end
    end

    # Default configuration for I/O format (.io.gbln.xz).
    #
    # - MINI format (compact)
    # - XZ compression enabled (level 6)
    # - Comments stripped
    #
    # @return [Config]
    def self.io_default
      new(mini_mode: true, compress: true, compression_level: 6, indent: 2, strip_comments: true)
    end

    # Default configuration for source code (.gbln).
    #
    # - Pretty format (with whitespace)
    # - No compression
    # - Comments preserved
    #
    # @return [Config]
    def self.source_default
      new(mini_mode: false, compress: false, compression_level: 0, indent: 2, strip_comments: false)
    end
  end
end
