require "rails_helper"

RSpec.describe CreateFormService do
  subject(:create_form_service) do
    described_class.new
  end

  let(:creator) { build :user, id: 100 }
  let(:group) { build :group, id: 1000, organisation: creator.organisation }
  let(:name) { "Test form" }

  describe "#create!" do
    it "creates a form" do
      expect {
        create_form_service.create!(creator:, group:, name:)
      }.to change(Form, :count).by(1)

      expect(Form.last).to have_attributes(creator_id: 100, name: "Test form")
    end

    it "creates a group_form record" do
      create_form_service.create!(creator:, group:, name:)

      expect(GroupForm.last).to have_attributes(form_id: Form.last.id, group_id: 1000)
    end

    context "when the group's organisation has a default brand" do
      let(:organisation) { create :organisation }
      let(:brand) { create :brand }
      let(:group) { build :group, id: 1000, organisation:, custom_branding_enabled: true }

      before do
        create(:organisation_brand, organisation:, brand:)
        organisation.update!(default_brand: brand)
      end

      it "creates the form with the default brand" do
        create_form_service.create!(creator:, group:, name:)

        expect(Form.last.brand_id).to eq brand.slug
      end

      context "when the group does not have custom branding enabled" do
        let(:group) { build :group, id: 1000, organisation:, custom_branding_enabled: false }

        it "creates the form without a brand" do
          create_form_service.create!(creator:, group:, name:)

          expect(Form.last.brand_id).to be_nil
        end
      end
    end

    context "when the group's organisation has no default brand" do
      let(:group) { build :group, id: 1000, organisation: creator.organisation, custom_branding_enabled: true }

      it "creates the form without a brand" do
        create_form_service.create!(creator:, group:, name:)

        expect(Form.last.brand_id).to be_nil
      end
    end

    context "when a form with that name was already created in that group" do
      before do
        allow(Form).to receive(:create!).and_call_original
      end

      context "when both forms are created at the same time" do
        it "creates only one form" do
          first = Thread.new { create_form_service.create!(creator:, group:, name:) }
          second = Thread.new { create_form_service.create!(creator:, group:, name:) }

          first = first.value
          second = second.value

          expect(Form).to have_received(:create!).once
          expect(second).to eq first
        end
      end

      context "when the previous form was created less than one second ago" do
        it "creates only one form" do
          first = create_form_service.create!(creator:, group:, name:)
          second = create_form_service.create!(creator:, group:, name:)

          expect(Form).to have_received(:create!).once
          expect(second).to eq first
        end
      end

      context "when the previous form was created more than one second ago" do
        it "creates two forms" do
          first = travel_to 2.seconds.ago do
            create_form_service.create!(creator:, group:, name:)
          end

          second = create_form_service.create!(creator:, group:, name:)

          expect(Form).to have_received(:create!).twice
          expect(second).not_to eq first
        end
      end

      context "when the previous form was created by a different user" do
        let(:other_creator) { build :user, organisation: creator.organisation }

        it "creates two forms" do
          first = create_form_service.create!(creator: other_creator, group:, name:)
          second = create_form_service.create!(creator:, group:, name:)

          expect(Form).to have_received(:create!).twice
          expect(second).not_to eq first
        end
      end
    end
  end
end
