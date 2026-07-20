require "rails_helper"

RSpec.describe Forms::SubmissionAttachmentsInput, type: :model do
  describe "validation" do
    let(:form) { create(:form) }

    context "when given a valid CSV and JSON submission format" do
      let(:submission_format) { %w[csv json] }

      it "validates succesfully" do
        submission_attachments_input = described_class.new(form:, submission_format:)

        expect(submission_attachments_input).to be_valid
      end
    end

    context "when given a valid no attachments submission format" do
      let(:submission_format) { [""] }

      it "validates succesfully" do
        submission_attachments_input = described_class.new(form:, submission_format:)

        expect(submission_attachments_input).to be_valid
      end
    end

    context "when given an invalid submission format" do
      let(:submission_format) { %w[apple json] }

      it "returns a validation error" do
        submission_attachments_input = described_class.new(form:, submission_format:)

        submission_attachments_input.validate

        expect(submission_attachments_input.errors.full_messages_for(:base)).to include("Sorry, there was a problem. Please try again.")
      end
    end

    context "when not given a submission format" do
      it "returns a validation error" do
        submission_attachments_input = described_class.new(form:)

        submission_attachments_input.validate

        expect(submission_attachments_input.errors.full_messages_for(:submission_format)).to include("Submission format Sorry, there was a problem. Please try again.")
      end
    end
  end

  describe "#submit" do
    subject(:submission_attachments_input) { described_class.new(form:, submission_format: updated_submission_format) }

    let(:form) { create(:form, submission_format: []) }

    context "when valid" do
      let(:updated_submission_format) { %w[csv] }

      it "updates the form's submission_format" do
        expect {
          submission_attachments_input.submit
        }.to change(form, :submission_format).to(updated_submission_format)
      end
    end

    context "when invalid" do
      let(:updated_submission_format) { %w[banana] }

      it "does not update the form's submission_format" do
        expect {
          submission_attachments_input.submit
        }.not_to change(form, :submission_format)
      end
    end

    context "when an immediate email DeliveryConfiguration exists" do
      let(:immediate_delivery_configuration) { create(:delivery_configuration, form:, formats: %w[csv]) }
      let(:daily_delivery_configuration) { create(:delivery_configuration, :daily_email, form:, formats: %w[csv]) }
      let(:updated_submission_format) { %w[csv json] }

      before do
        immediate_delivery_configuration
        daily_delivery_configuration
      end

      it "updates the immediate DeliveryConfiguration formats" do
        expect {
          submission_attachments_input.submit
        }.to change { immediate_delivery_configuration.reload.formats }.from(%w[csv]).to(updated_submission_format)

        expect(form.draft_form_document.reload.content["delivery_configurations"]).to contain_exactly(
          {
            "delivery_method" => "email",
            "delivery_schedule" => "immediate",
            "formats" => updated_submission_format,
          },
          {
            "delivery_method" => "email",
            "delivery_schedule" => "daily",
            "formats" => %w[csv],
          },
        )
      end

      it "does not change the daily DeliveryConfiguration formats" do
        expect {
          submission_attachments_input.submit
        }.not_to(change { daily_delivery_configuration.reload.formats })
      end
    end

    context "when an immediate email DeliveryConfiguration does not exist" do
      let(:s3_delivery_configuration) { create(:delivery_configuration, :s3, form:, formats: %w[csv]) }
      let(:daily_delivery_configuration) { create(:delivery_configuration, :daily_email, form:, formats: %w[csv]) }
      let(:updated_submission_format) { %w[csv json] }

      before do
        s3_delivery_configuration
        daily_delivery_configuration
      end

      it "creates an immediate email DeliveryConfiguration" do
        expect {
          submission_attachments_input.submit
        }.to change(DeliveryConfiguration, :count).by(1)

        expect(form.delivery_configurations.pluck(:delivery_method, :delivery_schedule, :formats)).to contain_exactly(
          ["email", "immediate", updated_submission_format],
          ["email", "daily", %w[csv]],
          ["s3", "immediate", %w[csv]],
        )

        expect(form.draft_form_document.reload.content["delivery_configurations"]).to include(
          {
            "delivery_method" => "email",
            "delivery_schedule" => "immediate",
            "formats" => updated_submission_format,
          },
        )
      end
    end
  end

  describe "#assign_form_values" do
    subject(:submission_attachments_input) { described_class.new(form:) }

    context "when the original form has an empty array submission format" do
      let(:form) { create(:form, submission_format: []) }

      it "sets the submission format value to an empty array" do
        submission_attachments_input.assign_form_values

        expect(submission_attachments_input.submission_format).to eq([])
      end
    end

    context "when the original form has a csv and json submission format" do
      let(:form) { create(:form, submission_format: %w[csv json]) }

      it "sets the submission format value to an empty array" do
        submission_attachments_input.assign_form_values

        expect(submission_attachments_input.submission_format).to eq(%w[csv json])
      end
    end
  end
end
