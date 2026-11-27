require "rails_helper"

describe Account::OrganisationInput do
  subject(:organisation_input) { described_class.new(pending_user:, allowed_organisations:) }

  let(:session) { {} }
  let(:pending_user) { PendingUser.start(session, provider: "auth0", uid: "123456", email: "user@example.gov.uk") }
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

      it "stores the organisation_id for the pending user" do
        organisation_input.submit
        expect(PendingUser.from_session(session).organisation_id).to eq(organisation.id.to_s)
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

      it "does not store the organisation_id for the pending user" do
        organisation_input.submit
        expect(PendingUser.from_session(session).organisation_id).to be_nil
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
    let(:pending_user) { PendingUser.start(session, provider: "auth0", uid: "123456", email: "user@example.gov.uk", organisation_id: organisation.id) }

    it "assigns the pending user's organisation_id to the form" do
      expect { organisation_input.assign_form_values }.to change(organisation_input, :organisation_id).to(organisation.id)
    end

    it "returns the form object" do
      expect(organisation_input.assign_form_values).to eq(organisation_input)
    end
  end
end
