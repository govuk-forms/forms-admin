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

      it "updates the form flags" do
        expect(form.reload.send_daily_submission_batch).to be(true)
        expect(form.reload.send_weekly_submission_batch).to be(true)
      end

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
    end

    context "when only daily is selected and both delivery configurations already exist" do
      let(:form) { create(:form, send_daily_submission_batch: true, send_weekly_submission_batch: true) }
      let(:batch_frequencies) { %w[daily] }

      before do
        create(:delivery_configuration, :daily_email, form:)
        create(:delivery_configuration, :weekly_email, form:)

        input.submit
      end

      it "updates the form flags" do
        expect(form.reload.send_daily_submission_batch).to be(true)
        expect(form.reload.send_weekly_submission_batch).to be(false)
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
    end

    context "when neither daily or weekly are selected" do
      let(:form) { create(:form, send_daily_submission_batch: true, send_weekly_submission_batch: true) }
      let(:batch_frequencies) { [] }

      before do
        create(:delivery_configuration, :daily_email, form:)
        create(:delivery_configuration, :weekly_email, form:)

        input.submit
      end

      it "clears the form flags" do
        expect(form.reload.send_daily_submission_batch).to be(false)
        expect(form.reload.send_weekly_submission_batch).to be(false)
      end

      it "removes all batch delivery configurations" do
        expect(form.delivery_configurations).to be_empty
      end

      it "updates the draft form document" do
        expect(form.draft_form_document.reload.content["delivery_configurations"]).to be_empty
      end
    end
  end

  describe "#assign_form_values" do
    subject(:input) { described_class.new(form:) }

    [
      [true, false, %w[daily]],
      [false, true, %w[weekly]],
      [true, true, %w[daily weekly]],
      [false, false, []],
    ].each do |send_daily_submission_batch, send_weekly_submission_batch, expected|
      context "when send_daily_submission_batch is #{send_daily_submission_batch} and send_weekly_submission_batch is #{send_weekly_submission_batch}" do
        let(:form) { create(:form, send_daily_submission_batch:, send_weekly_submission_batch:) }

        it "sets batch_frequencies to #{expected.inspect}" do
          input.assign_form_values

          expect(input.batch_frequencies).to match_array(expected)
        end
      end
    end
  end
end
