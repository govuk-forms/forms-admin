require "rails_helper"

RSpec.describe Account::ConfirmOrganisationInput do
  subject(:input) { described_class.new(organisation:) }

  let(:organisation) { build :organisation, name: "Ministry of Tests", abbreviation: "MOT" }

  describe "validations" do
    it "is valid when confirm is set to a valid value" do
      input.confirm = "yes"
      expect(input).to be_valid
    end

    it "is invalid when confirm is blank" do
      input.confirm = ""
      expect(input).to be_invalid

      expect(input.errors.full_messages_for(:confirm)).to include(
        "Confirm Select ‘Yes’ if you work for Ministry of Tests (MOT)",
      )
    end

    it "is invalid when confirm is set to an invalid value" do
      input.confirm = "invalid"
      expect(input).to be_invalid

      expect(input.errors.full_messages_for(:confirm)).to include(
        "Confirm Select ‘Yes’ if you work for Ministry of Tests (MOT)",
      )
    end
  end
end
