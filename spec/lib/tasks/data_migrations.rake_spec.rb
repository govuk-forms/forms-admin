require "rails_helper"

RSpec.describe "data_migrations.rake", type: :task do
  describe "data_migrations:create_delivery_configurations" do
    subject(:task) do
      Rake::Task["data_migrations:create_delivery_configurations"]
    end

    let(:form) do
      create(:form, :live_with_draft, submission_type: "email", submission_format: %w[csv json])
    end

    let!(:draft_form_document) do
      form.draft_form_document
    end

    it "has no delivery configurations before the task is run" do
      expect(form.delivery_configurations).to be_empty
    end

    it "creates a delivery configuration for the form" do
      task.invoke

      expect(form.reload.delivery_configurations.pluck(:delivery_method, :delivery_schedule, :formats)).to contain_exactly(
        ["email", "immediate", %w[csv json]],
      )
    end

    it "updates the draft form document" do
      task.invoke

      expect(draft_form_document.reload.content["delivery_configurations"]).to contain_exactly(
        {
          "delivery_method" => "email",
          "delivery_schedule" => "immediate",
          "formats" => %w[csv json],
        },
      )
    end

    context "when the live form document has different settings from the form" do
      let(:form) do
        create(:form, submission_type: "email", submission_format: [])
      end

      let!(:live_form_document) do
        create(
          :form_document,
          form:,
          tag: "live",
          language: "en",
          content: form.as_form_document.merge(
            "submission_type" => "s3",
            "submission_format" => %w[json],
          ),
        )
      end

      it "updates the live form document with the delivery configuration for the live form settings" do
        task.invoke

        expect(form.reload.delivery_configurations.pluck(:delivery_method, :delivery_schedule, :formats)).to contain_exactly(
          ["email", "immediate", []],
        )

        expect(live_form_document.reload.content["delivery_configurations"]).to contain_exactly(
          {
            "delivery_method" => "s3",
            "delivery_schedule" => "immediate",
            "formats" => %w[json],
          },
        )
      end
    end

    context "when the form sends daily and weekly submission batches" do
      let(:form) do
        create(:form, :live_with_draft, send_daily_submission_batch: true, send_weekly_submission_batch: true)
      end

      let!(:draft_form_document) do
        form.draft_form_document
      end

      it "creates immediate, daily, and weekly delivery configurations for the form" do
        task.invoke

        expect(form.reload.delivery_configurations.pluck(:delivery_method, :delivery_schedule, :formats)).to contain_exactly(
          ["email", "immediate", []],
          ["email", "daily", %w[csv]],
          ["email", "weekly", %w[csv]],
        )
      end

      it "updates the draft form document with all delivery configurations" do
        task.invoke

        expect(draft_form_document.reload.content["delivery_configurations"]).to contain_exactly(
          {
            "delivery_method" => "email",
            "delivery_schedule" => "immediate",
            "formats" => [],
          },
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

    it "does not duplicate delivery configurations when rerun" do
      task.invoke
      task.reenable
      task.invoke

      expect(form.reload.delivery_configurations.pluck(:delivery_method, :delivery_schedule, :formats)).to contain_exactly(
        ["email", "immediate", %w[csv json]],
      )
    end
  end
end
