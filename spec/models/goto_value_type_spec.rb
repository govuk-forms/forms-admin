require "rails_helper"

RSpec.describe GotoValueType do
  subject(:type) { described_class.new }

  describe "#cast" do
    it "casts 'default' to a DefaultValue" do
      expect(type.cast("default")).to eq(GotoValue::DefaultValue.new)
    end

    it "casts 'end_of_form' to an EndOfFormValue" do
      expect(type.cast("end_of_form")).to eq(GotoValue::EndOfFormValue.new)
    end

    it "casts a 'page_<id>' string to a Page" do
      expect(type.cast("page_5")).to eq(GotoValue::Page.new(5))
    end

    it "returns already-cast values unchanged" do
      value = GotoValue::Page.new(5)
      expect(type.cast(value)).to equal(value)
    end

    it "returns nil for a nil value" do
      expect(type.cast(nil)).to be_nil
    end

    it "returns nil for a blank string" do
      expect(type.cast("")).to be_nil
    end

    it "raises for an unrecognised value" do
      expect { type.cast("some_unrecognised_value") }.to raise_error(ArgumentError)
    end

    it "raises for a raw page id with no prefix" do
      expect { type.cast(5) }.to raise_error(ArgumentError)
    end
  end

  describe "#serialize" do
    it "serialises a value back to its string form" do
      expect(type.serialize(GotoValue::Page.new(5))).to eq("page_5")
    end

    it "serialises nil to nil" do
      expect(type.serialize(nil)).to be_nil
    end
  end
end
