# frozen_string_literal: true

RSpec.describe GBLN do
  it "has a version number" do
    expect(GBLN::VERSION).not_to be_nil
    expect(GBLN::VERSION).to match(/^\d+\.\d+\.\d+$/)
  end

  describe ".version" do
    it "returns the version string" do
      expect(GBLN.version).to eq(GBLN::VERSION)
    end
  end

  describe ".parse" do
    it "delegates to Parser.parse" do
      input = "user{id<u32>(12345)}"
      expect(GBLN::Parser).to receive(:parse).with(input).and_call_original
      GBLN.parse(input)
    end
  end

  describe ".parse_file" do
    it "delegates to Parser.parse_file" do
      path = "test.gbln"
      expect(GBLN::Parser).to receive(:parse_file).with(path).and_call_original
      expect { GBLN.parse_file(path) }.to raise_error(GBLN::IOError)
    end
  end

  describe ".to_string" do
    it "delegates to Serialiser.to_string with mini mode" do
      value = { user: { id: 12345 } }
      expect(GBLN::Serialiser).to receive(:to_string).with(value, mini: true).and_call_original
      GBLN.to_string(value, mini: true)
    end
  end

  describe ".to_string_pretty" do
    it "delegates to Serialiser.to_string_pretty" do
      value = { user: { id: 12345 } }
      expect(GBLN::Serialiser).to receive(:to_string_pretty).with(value, indent: 2).and_call_original
      GBLN.to_string_pretty(value, indent: 2)
    end
  end

  describe ".read_io" do
    it "delegates to IO.read_io" do
      path = "test.io.gbln.xz"
      expect(GBLN::IO).to receive(:read_io).with(path).and_call_original
      expect { GBLN.read_io(path) }.to raise_error(GBLN::IOError)
    end
  end

  describe ".write_io" do
    it "delegates to IO.write_io" do
      value = { user: { id: 12345 } }
      path = "test.io.gbln.xz"
      config = nil
      expect(GBLN::IO).to receive(:write_io).with(value, path, config).and_call_original
      expect { GBLN.write_io(value, path) }.to raise_error(GBLN::IOError)
    end
  end
end
