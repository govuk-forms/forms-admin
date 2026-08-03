require "rails_helper"

RSpec.describe Forms::MakeLiveInput, type: :model do
  let(:error_message) { I18n.t("activemodel.errors.models.forms/make_live_input.attributes.confirm.blank") }
  let(:form) { create :form, :ready_for_live }
  let(:user) { build :user }

  before do
    form.set_task_status_service(TaskStatusService.new(form:))
  end

  describe "validations" do
    it "is invalid if blank" do
      make_live_input = described_class.new(confirm: "")
      make_live_input.validate(:confirm)

      expect(make_live_input.errors.full_messages_for(:confirm)).to include(
        "Confirm #{error_message}",
      )
    end

    context "when all the required sections have been completed" do
      let(:form) { create :form, :ready_for_live, :with_submission_email }
      let(:make_live_input) { build :make_live_input, form: }

      before do
        make_live_input.confirm = "yes"
      end

      it "is valid" do
        expect(make_live_input).to be_valid
      end
    end

    context "when form is being made live but not all the required sections have been completed" do
      let(:form) { create :form, :ready_for_live }
      let(:make_live_input) { build :make_live_input, form: }

      before do
        make_live_input.confirm = "yes"
      end

      it "is invalid if submission_email is missing" do
        make_live_input.form.submission_email = nil

        expect(make_live_input).not_to be_valid
        expect(make_live_input.errors.full_messages_for(:confirm)).to include("Confirm #{I18n.t('activemodel.errors.models.forms/make_live_input.attributes.confirm.missing_submission_email')}")
      end

      context "when there are incomplete tasks" do
        let(:form) { create :form, :new_form, available_languages: %w[en cy] }
        let(:incomplete_tasks) { %i[missing_pages missing_privacy_policy_url missing_contact_details missing_what_happens_next share_preview_not_completed missing_welsh_translations] }

        it "shows a validation message for each incomplete task" do
          expect(make_live_input).not_to be_valid

          incomplete_tasks.each do |incomplete_task_name|
            expect(make_live_input.errors.full_messages_for(:confirm)).to include("Confirm #{I18n.t("activemodel.errors.models.forms/make_live_input.attributes.confirm.#{incomplete_task_name}")}")
          end
        end

        context "when no language is configured" do
          let(:make_live_input) { build :make_live_input, form: }
          let(:incomplete_tasks) { %i[missing_pages missing_privacy_policy_url missing_contact_details missing_what_happens_next share_preview_not_completed missing_welsh_translations] }

          it "shows a validation message for each incomplete task" do
            expect(make_live_input).not_to be_valid

            incomplete_tasks.each do |incomplete_task_name|
              expect(make_live_input.errors.full_messages_for(:confirm)).to include("Confirm #{I18n.t("activemodel.errors.models.forms/make_live_input.attributes.confirm.#{incomplete_task_name}")}")
            end
          end
        end

        context "when language is set to English" do
          let(:make_live_input) { build :make_live_input, form:, language: "en" }
          let(:incomplete_tasks) { %i[missing_pages missing_privacy_policy_url missing_contact_details missing_what_happens_next share_preview_not_completed] }

          it "shows a validation message for each incomplete task" do
            expect(make_live_input).not_to be_valid

            incomplete_tasks.each do |incomplete_task_name|
              expect(make_live_input.errors.full_messages_for(:confirm)).to include("Confirm #{I18n.t("activemodel.errors.models.forms/make_live_input.attributes.confirm.#{incomplete_task_name}")}")
            end
          end

          it "excludes the missing_welsh_translations task from the validation" do
            expect(make_live_input).not_to be_valid

            expect(make_live_input.errors.added?(:confirm, :missing_welsh_translations)).to be false
          end
        end

        context "when language is set to Welsh" do
          let(:make_live_input) { build :make_live_input, form:, language: "cy" }
          let(:incomplete_tasks) { %i[missing_pages missing_privacy_policy_url missing_contact_details missing_what_happens_next share_preview_not_completed missing_welsh_translations] }

          it "shows a validation message for each incomplete task" do
            expect(make_live_input).not_to be_valid

            incomplete_tasks.each do |incomplete_task_name|
              expect(make_live_input.errors.full_messages_for(:confirm)).to include("Confirm #{I18n.t("activemodel.errors.models.forms/make_live_input.attributes.confirm.#{incomplete_task_name}")}")
            end
          end
        end
      end
    end
  end
end
