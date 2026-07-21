require "rails_helper"

RSpec.describe Forms::BatchSubmissionsInput, type: :model do
  describe "#submit" do
    subject(:input) do
      described_class.new(
        form:,
        batch_frequencies:,
      )
    end

    context "when selecting both batch frequencies on a form without existing delivery configurations" do
      let(:form) { create(:form) }
      let(:batch_frequencies) { %w[daily weekly] }

      before { input.submit }

      it "creates delivery configurations for both frequencies" do
        expect(form.delivery_configurations.pluck(:delivery_method, :delivery_schedule, :formats)).to contain_exactly(
          ["email", "daily", %w[csv]], ["email", "weekly", %w[csv]]
        )
      end

      it "updates the draft form document" do
        expect(form.draft_form_document.reload.content["delivery_configurations"]).to contain_exactly(
          {
            "delivery_method" => "email",
            "delivery_schedule" => "daily",
            "formats" => %w[csv],
          },
          {
            "delivery_method" => "email",
            "delivery_schedule" => "weekly",
            "formats" => %w[csv],
          },
        )
      end

      it "reports that the delivery configurations changed" do
        expect(input.delivery_configurations_changed?).to be(true)
      end
    end

    context "when only daily is selected and both delivery configurations already exist" do
      let(:form) do
        create(:form, delivery_configurations: [
          create(:delivery_configuration, :daily_email),
          create(:delivery_configuration, :weekly_email),
        ])
      end
      let(:batch_frequencies) { %w[daily] }

      before do
        input.submit
      end

      it "keeps daily and removes weekly delivery configurations" do
        expect(form.delivery_configurations.order(:delivery_schedule).pluck(:delivery_method, :delivery_schedule, :formats)).to contain_exactly(
          ["email", "daily", %w[csv]],
        )
      end

      it "updates the draft form document" do
        expect(form.draft_form_document.reload.content["delivery_configurations"]).to contain_exactly(
          {
            "delivery_method" => "email",
            "delivery_schedule" => "daily",
            "formats" => %w[csv],
          },
        )
      end

      it "reports that the delivery configurations changed" do
        expect(input.delivery_configurations_changed?).to be(true)
      end
    end

    context "when neither daily or weekly are selected" do
      let(:form) do
        create(:form, delivery_configurations: [
          create(:delivery_configuration, :daily_email),
          create(:delivery_configuration, :weekly_email),
        ])
      end
      let(:batch_frequencies) { [] }

      before do
        input.submit
      end

      it "removes all batch delivery configurations" do
        expect(form.delivery_configurations).to be_empty
      end

      it "updates the draft form document" do
        expect(form.draft_form_document.reload.content["delivery_configurations"]).to be_empty
      end

      it "reports that the delivery configurations changed" do
        expect(input.delivery_configurations_changed?).to be(true)
      end
    end

    context "when the selected batch frequencies match the existing delivery configurations" do
      let(:form) do
        create(:form, delivery_configurations: [
          create(:delivery_configuration, :daily_email),
        ])
      end
      let(:batch_frequencies) { %w[daily] }

      before do
        input.submit
      end

      it "keeps the batch delivery configurations unchanged" do
        expect(form.delivery_configurations.pluck(:delivery_method, :delivery_schedule, :formats)).to contain_exactly(
          ["email", "daily", %w[csv]],
        )
      end

      it "reports that the delivery configurations did not change" do
        expect(input.delivery_configurations_changed?).to be(false)
      end
    end
  end

  describe "#assign_form_values" do
    subject(:input) { described_class.new(form:) }

    context "when the form has a daily batch delivery configuration" do
      let(:form) { create(:form, delivery_configurations: [create(:delivery_configuration, :daily_email)]) }

      it "sets batch_frequencies to daily" do
        input.assign_form_values

        expect(input.batch_frequencies).to match_array(%w[daily])
      end
    end

    context "when the form has a weekly batch delivery configuration" do
      let(:form) { create(:form, delivery_configurations: [create(:delivery_configuration, :weekly_email)]) }

      it "sets batch_frequencies to weekly" do
        input.assign_form_values

        expect(input.batch_frequencies).to match_array(%w[weekly])
      end
    end

    context "when the form has daily and weekly batch delivery configurations" do
      let(:form) do
        create(:form, delivery_configurations: [
          create(:delivery_configuration, :daily_email),
          create(:delivery_configuration, :weekly_email),
        ])
      end

      it "sets batch_frequencies to daily and weekly" do
        input.assign_form_values

        expect(input.batch_frequencies).to match_array(%w[daily weekly])
      end
    end

    context "when the form has no batch delivery configurations" do
      let(:form) { create(:form) }

      it "sets batch_frequencies to an empty array" do
        input.assign_form_values

        expect(input.batch_frequencies).to be_empty
      end
    end
  end
end
