require "rails_helper"

describe Account::OrganisationInput do
  subject(:organisation_input) { described_class.new(user:, allowed_organisations:) }

  let(:user) { create(:user, :with_no_org) }
  let(:organisation) { create(:organisation) }
  let(:allowed_organisations) { [organisation, *create_list(:organisation, 2)] }

  describe "validations" do
    it "is valid with a valid organisation_id" do
      organisation_input.organisation_id = organisation.id.to_s
      expect(organisation_input).to be_valid
    end

    it "is invalid without an organisation_id" do
      organisation_input.organisation_id = nil
      error_message = I18n.t("activemodel.errors.models.account/organisation_input.attributes.organisation_id.blank")
      expect(organisation_input).to be_invalid
      expect(organisation_input.errors[:organisation_id]).to include(error_message)
    end

    it "is invalid when the organisation is not in the allowed_organisations list" do
      organisation_input.organisation_id = create(:organisation).id.to_s
      error_message = I18n.t("activemodel.errors.models.account/organisation_input.attributes.organisation_id.inclusion")
      expect(organisation_input).to be_invalid
      expect(organisation_input.errors[:organisation_id]).to include(error_message)
    end
  end

  describe "#submit" do
    context "with valid attributes" do
      before do
        organisation_input.organisation_id = organisation.id.to_s
      end

      it "updates the user organisation_id" do
        expect { organisation_input.submit }.to change { user.reload.organisation_id }.to(organisation.id)
      end

      it "returns true" do
        expect(organisation_input.submit).to be true
      end

      it "logs the organisation_chosen event" do
        expect(Rails.logger).to receive(:info).with("User chose their organisation", {
          organisation_id: organisation.id.to_s,
        })
        organisation_input.submit
      end
    end

    context "with invalid attributes" do
      before do
        organisation_input.organisation_id = nil
      end

      it "does not update the user organisation_id" do
        expect { organisation_input.submit }.not_to(change { user.reload.organisation_id })
      end

      it "returns false" do
        expect(organisation_input.submit).to be false
      end

      it "does not log the organisation_chosen event" do
        expect(Rails.logger).not_to receive(:info)
        organisation_input.submit
      end
    end
  end

  describe "#assign_form_values" do
    let(:user) { create(:user) }

    it "assigns the user organisation_id to the form" do
      expect { organisation_input.assign_form_values }.to change(organisation_input, :organisation_id).to(user.organisation_id)
    end

    it "returns the form object" do
      expect(organisation_input.assign_form_values).to eq(organisation_input)
    end
  end
end
