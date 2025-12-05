# Changelog

All notable changes to the GBLN Ruby bindings will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial Ruby bindings implementation
- FFI wrapper for GBLN C library (libgbln)
- Complete type system support (i8-i64, u8-u64, f32, f64, s2-s1024, bool, null)
- Bidirectional value conversion between Ruby and GBLN
- Auto-type selection for integers and strings during serialisation
- Parser module with `parse()` and `parse_file()` methods
- Serialiser module with `to_string()` and `to_string_pretty()` methods
- I/O module with `read_io()` and `write_io()` for .io.gbln.xz files
- Configuration class with validation
- Comprehensive error hierarchy (ParseError, ValidationError, IOError, SerialiseError)
- Platform detection for 9 supported platforms
- Top-level convenience methods in GBLN module
- RSpec test suite with unit and integration tests
- YARD documentation throughout
- Rakefile with build, test, and documentation tasks
- Platform-specific library loading with fallback paths

### Technical Details
- Ruby >= 2.7.0 compatibility
- FFI gem for C library bindings
- Automatic memory management via FFI::AutoPointer
- UTF-8 string handling
- XZ (LZMA2) compression support via C library
- Cross-platform library detection (macOS, Linux, FreeBSD, Windows, Android)

## [0.9.0] - 2025-01-XX (Upcoming Beta Release)

Initial beta release of GBLN Ruby bindings.

### Features
- Full GBLN specification v1.0 support
- Type-safe parsing with parse-time validation
- Round-trip serialisation (parse → serialise → parse)
- Compressed I/O file support (.io.gbln.xz)
- Human-readable and minified output modes
- Comprehensive documentation and examples

### Supported Platforms
- macOS (ARM64, x86_64)
- Linux (x86_64, ARM64)
- FreeBSD (x86_64, ARM64)
- Windows (x86_64)
- Android (ARM64, x86_64)

[Unreleased]: https://github.com/gbln-org/gbln-ruby/compare/v0.9.0...HEAD
[0.9.0]: https://github.com/gbln-org/gbln-ruby/releases/tag/v0.9.0
