# frozen_string_literal: true

RSpec.describe "GBLN Integration Tests" do
  # These tests require the C library to be available
  # They are tagged as :integration and :requires_c_library

  describe "Parser and Serialiser round-trip", :integration, :requires_c_library do
    it "parses and serialises simple objects" do
      input = "user{id<u32>(12345)name<s64>(Alice)}"
      parsed = GBLN.parse(input)

      expect(parsed).to be_a(Hash)
      expect(parsed["user"]).to be_a(Hash)
      expect(parsed["user"]["id"]).to eq(12345)
      expect(parsed["user"]["name"]).to eq("Alice")

      # Round-trip
      serialised = GBLN.to_string(parsed, mini: true)
      expect(serialised).to include("user")
      expect(serialised).to include("12345")
      expect(serialised).to include("Alice")
    end

    it "handles arrays" do
      input = "tags<s16>[rust python golang]"
      parsed = GBLN.parse(input)

      expect(parsed).to be_a(Hash)
      expect(parsed["tags"]).to be_a(Array)
      expect(parsed["tags"]).to eq(["rust", "python", "golang"])
    end

    it "handles nested objects" do
      input = "app{config{port<u16>(8080)debug<b>(f)}}"
      parsed = GBLN.parse(input)

      expect(parsed["app"]["config"]["port"]).to eq(8080)
      expect(parsed["app"]["config"]["debug"]).to be false
    end

    it "handles all integer types" do
      input = <<~GBLN.strip
        numbers{
          i8_val<i8>(-128)
          i16_val<i16>(-32768)
          i32_val<i32>(-2147483648)
          u8_val<u8>(255)
          u16_val<u16>(65535)
          u32_val<u32>(4294967295)
        }
      GBLN

      parsed = GBLN.parse(input)
      expect(parsed["numbers"]["i8_val"]).to eq(-128)
      expect(parsed["numbers"]["u8_val"]).to eq(255)
    end

    it "handles floats" do
      input = "data{temp<f32>(22.5)price<f64>(19.99)}"
      parsed = GBLN.parse(input)

      expect(parsed["data"]["temp"]).to be_within(0.01).of(22.5)
      expect(parsed["data"]["price"]).to be_within(0.01).of(19.99)
    end

    it "handles booleans" do
      input = "flags{active<b>(t)enabled<b>(true)disabled<b>(f)off<b>(false)}"
      parsed = GBLN.parse(input)

      expect(parsed["flags"]["active"]).to be true
      expect(parsed["flags"]["enabled"]).to be true
      expect(parsed["flags"]["disabled"]).to be false
      expect(parsed["flags"]["off"]).to be false
    end

    it "handles null values" do
      input = "data{nothing<n>()empty<n>(null)}"
      parsed = GBLN.parse(input)

      expect(parsed["data"]["nothing"]).to be_nil
      expect(parsed["data"]["empty"]).to be_nil
    end
  end

  describe "Parser error handling", :integration, :requires_c_library do
    it "raises ParseError for invalid syntax" do
      expect { GBLN.parse("invalid{") }.to raise_error(GBLN::ParseError)
    end

    it "raises ValidationError for type violations" do
      # Value out of range for i8
      expect { GBLN.parse("value<i8>(999)") }.to raise_error(GBLN::ValidationError)
    end
  end

  describe "File I/O", :integration, :requires_c_library do
    let(:temp_file) { File.join(Dir.tmpdir, "test_#{Time.now.to_i}.gbln") }
    let(:temp_io_file) { File.join(Dir.tmpdir, "test_#{Time.now.to_i}.io.gbln.xz") }

    after do
      File.delete(temp_file) if File.exist?(temp_file)
      File.delete(temp_io_file) if File.exist?(temp_io_file)
    end

    it "parses files" do
      File.write(temp_file, "user{id<u32>(12345)}", encoding: "utf-8")
      parsed = GBLN.parse_file(temp_file)
      expect(parsed["user"]["id"]).to eq(12345)
    end

    it "writes and reads I/O files" do
      data = { user: { id: 12345, name: "Alice" } }

      GBLN.write_io(data, temp_io_file)
      expect(File.exist?(temp_io_file)).to be true

      loaded = GBLN.read_io(temp_io_file)
      expect(loaded["user"]["id"]).to eq(12345)
      expect(loaded["user"]["name"]).to eq("Alice")
    end
  end

  describe "Value conversion", :integration, :requires_c_library do
    it "auto-selects optimal integer types" do
      # Small positive → u8
      data = { value: 100 }
      gbln = GBLN.to_string(data)
      expect(gbln).to include("<u8>")

      # Small negative → i8
      data = { value: -50 }
      gbln = GBLN.to_string(data)
      expect(gbln).to include("<i8>")

      # Large positive → u32 or u64
      data = { value: 100_000 }
      gbln = GBLN.to_string(data)
      expect(gbln).to match(/<u(16|32|64)>/)
    end

    it "auto-selects optimal string types" do
      # Short string → s64
      data = { msg: "Hello" }
      gbln = GBLN.to_string(data)
      expect(gbln).to include("<s64>")

      # Long string → s256 or higher
      data = { msg: "A" * 100 }
      gbln = GBLN.to_string(data)
      expect(gbln).to match(/<s(128|256|512|1024)>/)
    end

    it "handles UTF-8 strings correctly" do
      data = { city: "北京" }
      gbln = GBLN.to_string(data)
      parsed = GBLN.parse(gbln)
      expect(parsed["city"]).to eq("北京")
    end
  end

  describe "Configuration options", :integration, :requires_c_library do
    it "respects mini_mode setting" do
      data = { user: { id: 12345 } }

      mini = GBLN.to_string(data, mini: true)
      pretty = GBLN.to_string(data, mini: false)

      expect(mini.length).to be < pretty.length
      expect(pretty).to include("\n")
    end

    it "uses custom compression levels for I/O" do
      data = { user: { id: 12345 } }
      temp_file = File.join(Dir.tmpdir, "test_compression_#{Time.now.to_i}.io.gbln.xz")

      config = GBLN::Config.new(compression_level: 9)
      GBLN.write_io(data, temp_file, config)

      expect(File.exist?(temp_file)).to be true
      File.delete(temp_file)
    end
  end
end
