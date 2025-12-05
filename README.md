# GBLN Ruby Bindings

[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)
[![Ruby Version](https://img.shields.io/badge/ruby-%3E%3D%202.7.0-red.svg)](https://www.ruby-lang.org)

Ruby bindings for **GBLN (Goblin Bounded Lean Notation)** - the first type-safe, LLM-optimised serialisation format.

## Features

- **Type-Safe**: Parse-time type validation with inline type hints
- **Memory-Efficient**: 70% smaller than JSON, 40% smaller than Protocol Buffers
- **LLM-Optimised**: 86% fewer tokens than JSON in AI contexts
- **Human-Readable**: Text-based format with clear, simple syntax
- **Git-Friendly**: Meaningful diffs, ordered keys preserved
- **Fast**: Native C library via FFI for performance
- **Cross-Platform**: Supports Linux, macOS, FreeBSD, Windows, Android

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'gbln'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install gbln
```

### Requirements

- Ruby >= 2.7.0
- GBLN C library (libgbln) - automatically located via:
  1. `GBLN_LIB_PATH` environment variable
  2. Bundled library (if packaged with gem)
  3. GBLN development tree
  4. System library paths

## Quick Start

```ruby
require 'gbln'

# Parse GBLN string
data = GBLN.parse('user{id<u32>(12345)name<s64>(Alice)age<i8>(25)}')
puts data["user"]["name"]  # => "Alice"

# Serialise to GBLN
user = { user: { id: 12345, name: "Alice", age: 25 } }
gbln = GBLN.to_string(user)
# => "user{id<u32>(12345)name<s64>(Alice)age<i8>(25)}"

# Pretty-print
puts GBLN.to_string_pretty(user)
# user{
#   id<u32>(12345)
#   name<s64>(Alice)
#   age<i8>(25)
# }

# Read from file
config = GBLN.parse_file('config.gbln')

# Write/read compressed I/O files (.io.gbln.xz)
GBLN.write_io(user, 'user.io.gbln.xz')
loaded = GBLN.read_io('user.io.gbln.xz')
```

## GBLN Syntax Overview

### Single Values
```ruby
GBLN.parse('name<s32>(Alice)')
# => {"name" => "Alice"}
```

### Objects
```ruby
gbln = <<~GBLN
  user{
    id<u32>(12345)
    name<s64>(Alice Johnson)
    age<i8>(25)
    active<b>(t)
  }
GBLN

data = GBLN.parse(gbln)
# => {"user" => {"id" => 12345, "name" => "Alice Johnson", "age" => 25, "active" => true}}
```

### Arrays
```ruby
GBLN.parse('tags<s16>[rust python golang]')
# => {"tags" => ["rust", "python", "golang"]}

GBLN.parse('users[{id<u32>(1)}{id<u32>(2)}]')
# => {"users" => [{"id" => 1}, {"id" => 2}]}
```

### Type System

| Category | Types | Ruby Mapping |
|----------|-------|--------------|
| **Signed Int** | i8, i16, i32, i64 | Integer |
| **Unsigned Int** | u8, u16, u32, u64 | Integer |
| **Float** | f32, f64 | Float |
| **String** | s2, s4, s8, s16, s32, s64, s128, s256, s512, s1024 | String |
| **Boolean** | b | TrueClass/FalseClass |
| **Null** | n | NilClass |

### Comments
```ruby
gbln = <<~GBLN
  :| This is a comment
  user{
    id<u32>(12345)  :| User identifier
    name<s64>(Alice)
  }
GBLN
```

## Advanced Usage

### Configuration

```ruby
# I/O configuration (for .io.gbln.xz files)
io_config = GBLN::Config.io_default
# => mini_mode: true, compress: true, compression_level: 6

# Source configuration (for .gbln files)
source_config = GBLN::Config.source_default
# => mini_mode: false, compress: false

# Custom configuration
custom_config = GBLN::Config.new(
  mini_mode: false,          # Pretty-print instead of compact
  compress: true,            # Enable XZ compression
  compression_level: 9,      # Maximum compression (0-9)
  indent: 4,                 # 4 spaces per indent level
  strip_comments: false      # Preserve comments
)

GBLN.write_io(data, 'output.io.gbln.xz', custom_config)
```

### Auto-Type Selection

When serialising Ruby data, GBLN automatically selects optimal types:

```ruby
# Integers - smallest type that fits
GBLN.to_string({ small: 100 })        # => "small<u8>(100)"
GBLN.to_string({ negative: -50 })     # => "negative<i8>(-50)"
GBLN.to_string({ large: 100_000 })    # => "large<u32>(100000)"

# Strings - based on UTF-8 character count
GBLN.to_string({ msg: "Hi" })         # => "msg<s64>(Hi)"
GBLN.to_string({ city: "北京" })       # => "city<s64>(北京)"  # 2 chars, not 6 bytes
```

### Error Handling

```ruby
begin
  GBLN.parse('invalid{')
rescue GBLN::ParseError => e
  puts "Parse error: #{e.message}"
end

begin
  GBLN.parse('value<i8>(999)')  # Out of range for i8
rescue GBLN::ValidationError => e
  puts "Validation error: #{e.message}"
end

begin
  GBLN.read_io('missing.io.gbln.xz')
rescue GBLN::IOError => e
  puts "I/O error: #{e.message}"
end
```

### Working with Files

```ruby
# Parse regular GBLN files
config = GBLN.parse_file('config.gbln')

# Read compressed I/O files
data = GBLN.read_io('data.io.gbln.xz')

# Write compressed I/O files
users = [
  { id: 1, name: "Alice" },
  { id: 2, name: "Bob" }
]

GBLN.write_io({ users: users }, 'users.io.gbln.xz')
```

## API Reference

### Top-Level Module

#### `GBLN.parse(gbln_string) → Object`
Parse a GBLN string into Ruby data structures.

#### `GBLN.parse_file(path) → Object`
Parse a GBLN file into Ruby data structures.

#### `GBLN.to_string(value, mini: true) → String`
Serialise Ruby data to GBLN string (compact or pretty).

#### `GBLN.to_string_pretty(value, indent: 2) → String`
Serialise Ruby data to pretty-printed GBLN string.

#### `GBLN.read_io(path) → Object`
Read and decompress a .io.gbln.xz file.

#### `GBLN.write_io(value, path, config = nil) → void`
Write and compress Ruby data to .io.gbln.xz file.

#### `GBLN.version → String`
Return the GBLN library version.

### Configuration Class

#### `GBLN::Config.new(**options) → Config`
Create a new configuration object.

**Options:**
- `mini_mode:` (Boolean) - Compact mode (default: true)
- `compress:` (Boolean) - Enable compression (default: true)
- `compression_level:` (Integer) - XZ compression level 0-9 (default: 6)
- `indent:` (Integer) - Spaces per indent level 0-8 (default: 2)
- `strip_comments:` (Boolean) - Remove comments (default: true)

#### `GBLN::Config.io_default → Config`
Default configuration for I/O files (compressed, compact).

#### `GBLN::Config.source_default → Config`
Default configuration for source files (uncompressed, pretty).

### Error Hierarchy

```
GBLN::Error (inherits from StandardError)
├── GBLN::ParseError - Invalid GBLN syntax
├── GBLN::ValidationError - Type validation failed
├── GBLN::IOError - File I/O errors
└── GBLN::SerialiseError - Serialisation errors
```

## Performance

**Size Comparison (1000 user records):**
- JSON: 156 KB
- Protocol Buffers: 42 KB
- **GBLN: 30 KB** ✨

**Token Efficiency (for LLMs):**
- JSON: 52,000 tokens
- **GBLN: 8,300 tokens** (84% reduction) ✨

**Parse Speed:**
- Approximately 30-50% slower than JSON
- Type safety validation included in parse time
- Acceptable for most use cases (not ultra-high-throughput)

## Use Cases

### Configuration Files
```ruby
# config.gbln
app{
  name<s32>(My Application)
  version<s16>(1.0.0)
  port<u16>(8080)
  debug<b>(f)
  workers<u8>(4)
}
```

### API Responses
```ruby
response = {
  status: 200,
  message: "Success",
  data: {
    user: {
      id: 12345,
      name: "Alice Johnson",
      role: "admin"
    }
  }
}

gbln = GBLN.to_string(response)
```

### IoT Device Communication
```ruby
sensor_data = {
  device_id: "SENS-ENV-001",
  readings: {
    temperature: 22.5,
    humidity: 65,
    battery: 87
  }
}

# Compact for network efficiency
GBLN.write_io(sensor_data, 'sensor.io.gbln.xz')
```

### LLM Fine-Tuning Data
```ruby
# 84% fewer tokens than JSON!
training_examples = [
  { prompt: "...", completion: "..." },
  # ... thousands more
]

GBLN.write_io(training_examples, 'training_data.io.gbln.xz')
```

## Platform Support

| Platform | Architecture | Library |
|----------|--------------|---------|
| macOS | ARM64 (M1/M2/M3) | libgbln.dylib |
| macOS | x86_64 (Intel) | libgbln.dylib |
| Linux | x86_64 | libgbln.so |
| Linux | ARM64 | libgbln.so |
| FreeBSD | x86_64 | libgbln.so |
| FreeBSD | ARM64 | libgbln.so |
| Windows | x86_64 | gbln.dll |
| Android | ARM64 | libgbln.so |
| Android | x86_64 | libgbln.so |

## Development

### Setup

```bash
git clone https://github.com/gbln-org/gbln-ruby.git
cd gbln-ruby
bundle install
```

### Running Tests

```bash
# Run all tests
bundle exec rake spec

# Run with coverage
bundle exec rake spec:coverage

# Run specific tests
bundle exec rspec spec/gbln_spec.rb
```

### Code Quality

```bash
# Run RuboCop
bundle exec rake rubocop

# Auto-correct issues
bundle exec rake rubocop:autocorrect
```

### Documentation

```bash
# Generate YARD documentation
bundle exec rake yard

# View documentation
open doc/index.html
```

### Building the Gem

```bash
# Build gem package
bundle exec rake build

# Install locally
bundle exec rake install
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

Copyright (c) 2025 Vivian Burkhard Voss

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

## Links

- **Website**: [gbln.dev](https://gbln.dev)
- **Documentation**: [gbln.dev/docs/ruby](https://gbln.dev/docs/ruby)
- **GitHub**: [github.com/gbln-org/gbln-ruby](https://github.com/gbln-org/gbln-ruby)
- **Issues**: [github.com/gbln-org/gbln-ruby/issues](https://github.com/gbln-org/gbln-ruby/issues)
- **Specification**: [github.com/gbln-org/gbln](https://github.com/gbln-org/gbln)

## Support

For questions, bug reports, or feature requests:
- Open an issue on [GitHub](https://github.com/gbln-org/gbln-ruby/issues)
- Email: ask@vvoss.dev

---

**GBLN** - Type-safe data that speaks clearly 🦇
