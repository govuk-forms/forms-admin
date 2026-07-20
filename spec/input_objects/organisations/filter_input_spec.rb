require "rails_helper"

RSpec.describe Organisations::FilterInput, type: :model do
  describe "#has_filters?" do
    context "when the name filter is set" do
      subject(:input) { described_class.new(name: "foo") }

      it "returns true" do
        expect(input.has_filters?).to be true
      end
    end

    context "when the agreement_type filter is set" do
      subject(:input) { described_class.new(agreement_type: "crown") }

      it "returns true" do
        expect(input.has_filters?).to be true
      end
    end

    context "when no filters are set" do
      subject(:input) { described_class.new }

      it "returns false" do
        expect(input.has_filters?).to be false
      end
    end
  end

  describe "#sort_options" do
    it "returns the correct options" do
      expect(described_class.new.sort_options).to eq([
        OpenStruct.new(label: I18n.t("organisations.index.filter.sort.name"), value: "name"),
        OpenStruct.new(label: I18n.t("organisations.index.filter.sort.users"), value: "users"),
        OpenStruct.new(label: I18n.t("organisations.index.filter.sort.live_forms"), value: "live_forms"),
        OpenStruct.new(label: I18n.t("organisations.index.filter.sort.draft_forms"), value: "draft_forms"),
        OpenStruct.new(label: I18n.t("organisations.index.filter.sort.agreement_date"), value: "agreement_date"),
      ])
    end
  end

  describe "#agreement_type_options" do
    it "returns the correct options" do
      expect(described_class.new.agreement_type_options).to eq([
        OpenStruct.new(label: I18n.t("organisations.index.filter.agreement_type.any")),
        OpenStruct.new(label: I18n.t("mou_signatures.index.agreement_type.crown"), value: "crown"),
        OpenStruct.new(label: I18n.t("mou_signatures.index.agreement_type.non_crown"), value: "non_crown"),
        OpenStruct.new(label: I18n.t("organisations.index.filter.agreement_type.signed"), value: "signed"),
        OpenStruct.new(label: I18n.t("organisations.index.filter.agreement_type.none"), value: "none"),
      ])
    end
  end
end
