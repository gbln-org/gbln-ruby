# frozen_string_literal: true

RSpec.describe GBLN::Config do
  describe "#initialize" do
    it "creates a config with default values" do
      config = described_class.new
      expect(config.mini_mode).to be true
      expect(config.compress).to be true
      expect(config.compression_level).to eq(6)
      expect(config.indent).to eq(2)
      expect(config.strip_comments).to be true
    end

    it "accepts custom values" do
      config = described_class.new(
        mini_mode: false,
        compress: false,
        compression_level: 9,
        indent: 4,
        strip_comments: false
      )
      expect(config.mini_mode).to be false
      expect(config.compress).to be false
      expect(config.compression_level).to eq(9)
      expect(config.indent).to eq(4)
      expect(config.strip_comments).to be false
    end

    it "validates compression level range" do
      expect { described_class.new(compression_level: -1) }.to raise_error(ArgumentError, /between 0 and 9/)
      expect { described_class.new(compression_level: 10) }.to raise_error(ArgumentError, /between 0 and 9/)
    end

    it "validates indent range" do
      expect { described_class.new(indent: -1) }.to raise_error(ArgumentError, /between 0 and 8/)
      expect { described_class.new(indent: 9) }.to raise_error(ArgumentError, /between 0 and 8/)
    end
  end

  describe ".io_default" do
    it "returns config suitable for I/O operations" do
      config = described_class.io_default
      expect(config.mini_mode).to be true
      expect(config.compress).to be true
      expect(config.compression_level).to eq(6)
      expect(config.indent).to eq(2)
      expect(config.strip_comments).to be true
    end
  end

  describe ".source_default" do
    it "returns config suitable for source files" do
      config = described_class.source_default
      expect(config.mini_mode).to be false
      expect(config.compress).to be false
      expect(config.compression_level).to eq(0)
      expect(config.indent).to eq(2)
      expect(config.strip_comments).to be false
    end
  end

  describe "#validate" do
    it "does not raise for valid configuration" do
      config = described_class.new
      expect { config.validate }.not_to raise_error
    end

    it "raises for invalid compression level" do
      config = described_class.new(compression_level: 5)
      config.compression_level = 99
      expect { config.validate }.to raise_error(ArgumentError, /compression_level must be between 0 and 9/)
    end

    it "raises for invalid indent" do
      config = described_class.new(indent: 2)
      config.indent = 99
      expect { config.validate }.to raise_error(ArgumentError, /indent must be between 0 and 8/)
    end
  end
end
