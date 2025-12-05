# frozen_string_literal: true

RSpec.describe "GBLN Error Hierarchy" do
  describe GBLN::Error do
    it "inherits from StandardError" do
      expect(GBLN::Error.new).to be_a(StandardError)
    end

    it "can be raised with a message" do
      expect { raise GBLN::Error, "test error" }.to raise_error(GBLN::Error, "test error")
    end
  end

  describe GBLN::ParseError do
    it "inherits from GBLN::Error" do
      expect(GBLN::ParseError.new).to be_a(GBLN::Error)
    end

    it "can be raised with a message" do
      expect { raise GBLN::ParseError, "parse failed" }.to raise_error(GBLN::ParseError, "parse failed")
    end
  end

  describe GBLN::ValidationError do
    it "inherits from GBLN::Error" do
      expect(GBLN::ValidationError.new).to be_a(GBLN::Error)
    end

    it "can be raised with a message" do
      expect { raise GBLN::ValidationError, "invalid type" }.to raise_error(GBLN::ValidationError, "invalid type")
    end
  end

  describe GBLN::IOError do
    it "inherits from GBLN::Error" do
      expect(GBLN::IOError.new).to be_a(GBLN::Error)
    end

    it "can be raised with a message" do
      expect { raise GBLN::IOError, "file not found" }.to raise_error(GBLN::IOError, "file not found")
    end
  end

  describe GBLN::SerialiseError do
    it "inherits from GBLN::Error" do
      expect(GBLN::SerialiseError.new).to be_a(GBLN::Error)
    end

    it "can be raised with a message" do
      expect { raise GBLN::SerialiseError, "cannot serialise" }.to raise_error(GBLN::SerialiseError, "cannot serialise")
    end
  end
end
