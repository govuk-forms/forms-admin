require "rails_helper"

describe TaskStatusService do
  subject(:task_status_service) do
    described_class.new(form:, current_user:)
  end

  let(:group) { create :group }

  let(:current_user) { build(:user, role: :standard) }

  before do
    form.set_task_status_service(task_status_service)
  end

  describe "statuses" do
    describe "name status" do
      let(:form) { build(:form, :new_form, :with_group, group:) }

      it "returns the correct default value" do
        expect(task_status_service.all_task_statuses[:name_status]).to eq :completed
      end
    end

    describe "pages status" do
      context "with a new form" do
        let(:form) { build(:form, :new_form, :with_group, group:) }

        it "returns the correct default value" do
          expect(task_status_service.all_task_statuses[:pages_status]).to eq :not_started
        end
      end

      context "with a form which has pages" do
        let(:form) { build(:form, :new_form, :with_pages, :with_group, question_section_completed: false, group:) }

        it "returns the in progress status" do
          expect(task_status_service.all_task_statuses[:pages_status]).to eq :in_progress
        end

        context "and questions marked completed" do
          let(:form) { build(:form, :new_form, :with_pages, :with_group, question_section_completed: true, group:) }

          it "returns the completed status" do
            expect(task_status_service.all_task_statuses[:pages_status]).to eq :completed
          end
        end
      end
    end

    describe "declaration status" do
      context "with a new form" do
        let(:form) { build(:form, :new_form, :with_group, group:) }

        it "returns the correct default value" do
          expect(task_status_service.all_task_statuses[:declaration_status]).to eq :not_started
        end
      end

      context "with a form which has no declaration content and is marked incomplete" do
        let(:form) { build(:form, :with_group, declaration_section_completed: false, group:) }

        it "returns the not started status" do
          expect(task_status_service.all_task_statuses[:declaration_status]).to eq :not_started
        end
      end

      context "with a form which has declaration content and is marked incomplete" do
        let(:form) { build(:form, :with_group, declaration_markdown: "I understand the implications", declaration_section_completed: false, group:) }

        it "returns the in progress status" do
          expect(task_status_service.all_task_statuses[:declaration_status]).to eq :in_progress
        end
      end

      context "with a form which has a declaration marked complete" do
        let(:form) { build(:form, :with_group, declaration_section_completed: true, group:) }

        it "returns the completed status" do
          expect(task_status_service.all_task_statuses[:declaration_status]).to eq :completed
        end
      end
    end

    describe "what happens next status" do
      context "with a new form" do
        let(:form) { build(:form, :new_form, :with_group, group:) }

        it "returns the correct default value" do
          expect(task_status_service.all_task_statuses[:what_happens_next_status]).to eq :not_started
        end
      end

      context "with a form which has a what_happens_next_markdown" do
        let(:form) { build(:form, :new_form, :with_group, what_happens_next_markdown: "We usually respond to applications within 10 working days.", group:) }

        it "returns the completed status" do
          expect(task_status_service.all_task_statuses[:what_happens_next_status]).to eq :completed
        end
      end
    end

    describe "payment link status" do
      context "with a new form" do
        let(:form) { build(:form, :new_form, :with_group, group:) }

        it "returns the correct default value" do
          expect(task_status_service.all_task_statuses[:payment_link_status]).to eq :optional
        end
      end

      context "with a form with a payment link" do
        let(:form) { build(:form, :new_form, :with_group, payment_url: Faker::Internet.url(host: "gov.uk"), group:) }

        it "returns the completed status" do
          expect(task_status_service.all_task_statuses[:payment_link_status]).to eq :completed
        end
      end
    end

    describe "brand status" do
      context "with a new form" do
        let(:form) { build(:form, :new_form, :with_group, group:) }

        it "returns the correct default value" do
          expect(task_status_service.all_task_statuses[:brand_status]).to eq :optional
        end
      end

      context "with a form with a brand" do
        let(:form) { build(:form, :new_form, :with_group, :with_brand, group:) }

        it "returns the completed status" do
          expect(task_status_service.all_task_statuses[:brand_status]).to eq :completed
        end
      end
    end

    describe "copy of answers status" do
      context "with a new form" do
        let(:form) { build(:form, :new_form, :with_group, group:) }

        it "returns the correct default value" do
          expect(task_status_service.all_task_statuses[:copy_of_answers_status]).to eq :optional
        end
      end

      context "with a form with copy of answers enabled" do
        let(:form) { build(:form, :with_group, send_copy_of_answers: "enabled", group:) }

        it "returns the completed status" do
          expect(task_status_service.all_task_statuses[:copy_of_answers_status]).to eq :completed
        end
      end
    end

    describe "privacy policy status" do
      context "with a new form" do
        let(:form) { build(:form, :new_form, :with_group, group:) }

        it "returns the correct default value" do
          expect(task_status_service.all_task_statuses[:privacy_policy_status]).to eq :not_started
        end
      end

      context "with a form which has a privacy policy section" do
        let(:form) { build(:form, :new_form, :with_group, privacy_policy_url: Faker::Internet.url(host: "gov.uk"), group:) }

        it "returns the in progress status" do
          expect(task_status_service.all_task_statuses[:privacy_policy_status]).to eq :completed
        end
      end
    end

    describe "support contact details status status" do
      context "with a new form" do
        let(:form) { build(:form, :new_form, :with_group, group:) }

        it "returns the correct default value" do
          expect(task_status_service.all_task_statuses[:support_contact_details_status]).to eq :not_started
        end
      end

      context "with a form which has contact details set" do
        let(:form) { build(:form, :new_form, :with_support, :with_group, group:) }

        it "returns the in progress status" do
          expect(task_status_service.all_task_statuses[:support_contact_details_status]).to eq :completed
        end
      end
    end

    describe "submission_attachments_status" do
      context "with a new form" do
        let(:form) { build(:form, :new_form, :with_group, group:) }

        it "returns optional" do
          expect(task_status_service.all_task_statuses[:submission_attachments_status]).to eq :optional
        end
      end

      context "with submission_type set to 'email'" do
        let(:form) { build(:form, :new_form, :with_group, submission_type: "email", submission_format:, group:) }

        context "with submission format empty" do
          let(:submission_format) { [] }

          it "returns optional" do
            expect(task_status_service.all_task_statuses[:submission_attachments_status]).to eq :optional
          end
        end

        context "with submission format csv" do
          let(:submission_format) { %w[csv] }

          it "returns completed" do
            expect(task_status_service.all_task_statuses[:submission_attachments_status]).to eq :completed
          end
        end

        context "with submission format has multiple values" do
          let(:submission_format) { %w[csv json] }

          it "returns completed" do
            expect(task_status_service.all_task_statuses[:submission_attachments_status]).to eq :completed
          end
        end
      end

      context "with submission_type set s3" do
        let(:form) { build(:form, :new_form, :with_group, submission_type: "s3", submission_format: "csv", group:) }

        it "returns optional" do
          expect(task_status_service.all_task_statuses[:submission_attachments_status]).to eq :optional
        end
      end
    end

    describe "batch_submissions_status" do
      let(:form) { build(:form, :new_form, :with_group, group:, send_daily_submission_batch:, send_weekly_submission_batch:) }

      context "with send_daily_submission_batch set to true" do
        let(:send_daily_submission_batch) { true }
        let(:send_weekly_submission_batch) { false }

        it "returns completed" do
          expect(task_status_service.all_task_statuses[:batch_submissions_status]).to eq :completed
        end
      end

      context "with send_weekly_submission_batch set to true" do
        let(:send_daily_submission_batch) { false }
        let(:send_weekly_submission_batch) { true }

        it "returns completed" do
          expect(task_status_service.all_task_statuses[:batch_submissions_status]).to eq :completed
        end
      end

      context "with send daily and weekly batches set to false" do
        let(:send_daily_submission_batch) { false }
        let(:send_weekly_submission_batch) { false }

        it "returns optional" do
          expect(task_status_service.all_task_statuses[:batch_submissions_status]).to eq :optional
        end
      end
    end

    describe "share_preview_status" do
      context "with share_preview_completed set to false" do
        context "when the form does not have any pages" do
          let(:form) { build(:form, :new_form, :with_group, group:) }

          it "returns cannot_start" do
            expect(task_status_service.all_task_statuses[:share_preview_status]).to eq :cannot_start
          end
        end

        context "when the form has pages" do
          let(:form) { build(:form, :with_pages, :with_group, group:) }

          it "returns not_started" do
            expect(task_status_service.all_task_statuses[:share_preview_status]).to eq :not_started
          end
        end
      end

      context "with share_preview_completed set to true" do
        context "when the form does not have any pages" do
          let(:form) { build(:form, :new_form, :with_group, share_preview_completed: true, group:) }

          it "returns cannot_start" do
            expect(task_status_service.all_task_statuses[:share_preview_status]).to eq :cannot_start
          end
        end

        context "when the form has pages" do
          let(:form) { build(:form, :with_pages, :with_group, share_preview_completed: true, group:) }

          it "returns completed" do
            expect(task_status_service.all_task_statuses[:share_preview_status]).to eq :completed
          end
        end
      end
    end

    describe "welsh_language_status" do
      context "and Welsh translation is not started" do
        let(:form) { create(:form, :live, :with_group, available_languages: %w[en], welsh_completed: false, group:) }

        it "returns optional" do
          expect(task_status_service.all_task_statuses[:welsh_language_status]).to eq :optional
        end
      end

      context "and Welsh translation is completed" do
        let(:form) { create(:form, :live, :with_group, :with_welsh_translation, group:) }

        it "returns completed" do
          expect(task_status_service.all_task_statuses[:welsh_language_status]).to eq :completed
        end

        context "and the support email contains a non-gov.uk email with the same domain as the user" do
          let(:current_user) { build(:user, role: :standard, email: "example@example.com") }
          let(:form) { create(:form, :ready_for_live, :with_group, :with_welsh_translation, welsh_completed: true, group:, support_email_cy: "support@example.com") }

          it "returns completed" do
            expect(task_status_service.all_task_statuses[:welsh_language_status]).to eq :completed
          end
        end
      end

      context "and structural changes require Welsh updates" do
        let(:form) { create(:form, :live, :with_group, available_languages: %w[en cy], welsh_completed: true, group:) }

        before do
          # Create initial Welsh FormDocument
          FormDocumentSyncService.new(form).synchronize_live_form
          # Add new content requiring Welsh translation
          form.update!(declaration_markdown: "I declare this is correct")
          form.save_question_changes!
        end

        it "returns in_progress" do
          expect(task_status_service.all_task_statuses[:welsh_language_status]).to eq :in_progress
        end
      end

      context "and Welsh is started but not completed" do
        let(:form) { build(:form, :new_form, :with_group, available_languages: %w[en cy], welsh_completed: false, group:) }

        it "returns in_progress" do
          expect(task_status_service.all_task_statuses[:welsh_language_status]).to eq :in_progress
        end
      end
    end

    describe "make live status" do
      context "with a new form" do
        let(:form) { build(:form, :new_form, :with_group, group:) }

        it "returns the correct default value" do
          expect(task_status_service.all_task_statuses[:make_live_status]).to eq :cannot_start
        end
      end

      context "with a form which is ready to go live" do
        let(:form) { build(:form, :ready_for_live, :with_group, group:) }

        it "returns the not started status" do
          expect(task_status_service.all_task_statuses[:make_live_status]).to eq :not_started
        end
      end

      context "with a live form with a draft and all tasks complete" do
        let(:form) { build(:form, :ready_for_live, :with_group, state: :live_with_draft, group:) }

        it "returns the not started status" do
          expect(task_status_service.all_task_statuses[:make_live_status]).to eq :not_started
        end
      end

      context "with an archived form with a draft and incomplete tasks" do
        let(:form) { build(:form, :with_group, state: :archived_with_draft, group:) }

        it "returns the not started status" do
          expect(task_status_service.all_task_statuses[:make_live_status]).to eq :cannot_start
        end
      end

      context "with an archived form with a draft and all tasks complete" do
        let(:form) { build(:form, :ready_for_live, :with_group, state: :archived_with_draft, group:) }

        it "returns the not started status" do
          expect(task_status_service.all_task_statuses[:make_live_status]).to eq :not_started
        end
      end

      context "with a live form" do
        let(:form) { create(:form, :live, :with_group, group:) }

        it "returns the completed status" do
          expect(task_status_service.all_task_statuses[:make_live_status]).to eq :completed
        end
      end

      context "with an archived form" do
        let(:form) { build(:form, :with_group, state: :archived, group:) }

        it "returns the completed status" do
          expect(task_status_service.all_task_statuses[:make_live_status]).to eq :not_started
        end
      end
    end

    describe "make_only_english_live_status" do
      let(:can_make_english_live) { false }
      let(:can_make_welsh_live) { false }
      let(:changed_from_live_version) { false }

      let(:form) { build(:form, :with_group, group:) }

      before do
        allow(form).to receive(:can_make_language_live?).with(language: "en").and_return(can_make_english_live)
        allow(form).to receive(:changed_from_live_version?).with(language: "en").and_return(changed_from_live_version)
        allow(form).to receive(:can_make_language_live?).with(language: "cy").and_return(can_make_welsh_live)
      end

      context "with a new form" do
        let(:form) { build(:form, :new_form, :with_group, group:) }

        it "returns the correct default value" do
          expect(task_status_service.all_task_statuses[:make_only_english_live_status]).to eq :cannot_start
        end
      end

      context "when the English version can be made live" do
        let(:can_make_english_live) { true }

        it "returns not started" do
          expect(task_status_service.all_task_statuses[:make_only_english_live_status]).to eq :not_started
        end
      end

      context "when the English version cannot be made live" do
        let(:can_make_english_live) { false }

        context "when the form is live" do
          let(:form) { build(:form, :live, :with_group, group:) }

          it "returns completed" do
            expect(task_status_service.all_task_statuses[:make_only_english_live_status]).to eq :completed
          end
        end

        context "when the form is live with draft" do
          let(:form) { build(:form, :live_with_draft, :with_group, group:) }

          context "when there are changes from the English form document" do
            let(:changed_from_live_version) { true }

            it "returns cannot_start" do
              expect(task_status_service.all_task_statuses[:make_only_english_live_status]).to eq :cannot_start
            end
          end

          context "when there are no changes from the English form document" do
            let(:changed_from_live_version) { false }

            it "returns completed" do
              expect(task_status_service.all_task_statuses[:make_only_english_live_status]).to eq :completed
            end
          end
        end

        context "when the form is a draft" do
          let(:form) { build(:form, :ready_for_live, :with_group, group:) }

          it "returns cannot_start" do
            expect(task_status_service.all_task_statuses[:make_only_english_live_status]).to eq :cannot_start
          end
        end

        context "when the form is archived" do
          let(:form) { build(:form, :archived, :with_group, group:) }

          it "returns cannot_start" do
            expect(task_status_service.all_task_statuses[:make_only_english_live_status]).to eq :cannot_start
          end
        end

        context "when the form is archived with draft" do
          let(:form) { build(:form, :archived_with_draft, :with_group, group:) }

          it "returns cannot_start" do
            expect(task_status_service.all_task_statuses[:make_only_english_live_status]).to eq :cannot_start
          end
        end
      end
    end

    describe "make_only_welsh_live_status" do
      let(:can_make_english_live) { true }
      let(:can_make_welsh_live) { false }

      let(:form) { build(:form, :with_group, group:) }

      before do
        allow(form).to receive(:can_make_language_live?).with(language: "en").and_return(can_make_english_live)
        allow(form).to receive(:can_make_language_live?).with(language: "cy").and_return(can_make_welsh_live)
      end

      context "with a new form" do
        let(:form) { build(:form, :new_form, :with_group, group:) }

        it "returns the correct default value" do
          expect(task_status_service.all_task_statuses[:make_only_welsh_live_status]).to eq :cannot_start
        end
      end

      context "when the Welsh version can be made live" do
        let(:can_make_welsh_live) { true }

        it "returns not started" do
          expect(task_status_service.all_task_statuses[:make_only_welsh_live_status]).to eq :not_started
        end
      end

      context "when the Welsh version cannot be made live" do
        let(:can_make_welsh_live) { false }
        let(:welsh_form_document) { build(:form_document, :live, form:, language: "cy", content: form.as_form_document) }

        before do
          allow(form).to receive(:live_welsh_form_document).and_return(welsh_form_document)
        end

        context "when the form already has a live Welsh version" do
          it "returns completed" do
            expect(task_status_service.all_task_statuses[:make_only_welsh_live_status]).to eq :completed
          end
        end

        context "when the form does not have a live Welsh version" do
          let(:welsh_form_document) { nil }

          it "returns cannot start" do
            expect(task_status_service.all_task_statuses[:make_only_welsh_live_status]).to eq :cannot_start
          end
        end
      end
    end
  end

  describe "#mandatory_tasks_completed" do
    context "when mandatory tasks have not been completed" do
      let(:form) { build(:form, :new_form, :with_group, group:) }

      it "returns false" do
        expect(task_status_service.mandatory_tasks_completed?).to be false
      end
    end

    context "when mandatory tasks have been completed" do
      let(:form) { build(:form, :ready_for_live, :with_group, group:) }

      it "returns true" do
        expect(task_status_service.mandatory_tasks_completed?).to be true
      end
    end

    context "when missing_welsh_translations is present" do
      let(:form) { build(:form, :ready_for_live, :with_welsh_translation, welsh_completed: false) }

      it "when ignore_missing_welsh is true returns true" do
        expect(task_status_service.mandatory_tasks_completed?(ignore_missing_welsh: true)).to be true
      end

      it "without ignore_missing_welsh returns false" do
        expect(task_status_service.mandatory_tasks_completed?).to be false
      end
    end
  end

  describe "#all_incomplete_tasks" do
    context "when mandatory tasks are complete" do
      let(:form) { build(:form, :live, :with_group, group:) }

      context "when the Welsh feature is not enabled" do
        let(:group) { create(:group) }

        it "returns no missing sections" do
          expect(task_status_service.all_incomplete_tasks).to be_empty
        end
      end

      context "when the Welsh feature is enabled" do
        context "when the optional Welsh task has not been started" do
          let(:form) { create(:form, :live, :with_group, available_languages: %w[en], welsh_completed: false, group:) }

          it "returns no missing sections" do
            expect(task_status_service.all_incomplete_tasks).to be_empty
          end
        end

        context "when the optional Welsh task has been completed" do
          let(:form) { create(:form, :live, :with_group, available_languages: %w[en cy], welsh_completed: true, group:) }

          before do
            welsh_translation_input = instance_double(Forms::WelshTranslationInput)
            allow(welsh_translation_input).to receive_messages(assign_form_values: welsh_translation_input, invalid?: false)
            allow(Forms::WelshTranslationInput).to receive(:new).and_return(welsh_translation_input)
          end

          it "returns no missing sections" do
            expect(task_status_service.all_incomplete_tasks).to be_empty
          end
        end

        context "and the form has structural changes require Welsh updates" do
          let(:form) { create(:form, :live, :with_group, available_languages: %w[en cy], welsh_completed: true, group:) }

          before do
            # Create initial Welsh FormDocument
            FormDocumentSyncService.new(form).synchronize_live_form
            # Add new content requiring Welsh translation
            form.update!(declaration_markdown: "I declare this is correct", share_preview_completed: true)
          end

          it "flags the Welsh task as incomplete" do
            expect(task_status_service.all_incomplete_tasks).to match_array(%i[missing_welsh_translations])
          end
        end

        context "when the optional Welsh task has been started but not completed" do
          let(:form) { build(:form, :live, :with_group, available_languages: %w[en cy], welsh_completed: false, group:) }

          it "flags the Welsh task as incomplete" do
            expect(task_status_service.all_incomplete_tasks).to match_array(%i[missing_welsh_translations])
          end
        end

        context "when the ignore_missing_welsh argument is `true`" do
          context "and the form has structural changes require Welsh updates" do
            let(:form) { create(:form, :live, :with_group, available_languages: %w[en cy], welsh_completed: true, group:) }

            before do
              # Create initial Welsh FormDocument
              FormDocumentSyncService.new(form).synchronize_live_form
              # Add new content requiring Welsh translation
              form.update!(declaration_markdown: "I declare this is correct", share_preview_completed: true)
            end

            it "returns no missing sections" do
              expect(task_status_service.all_incomplete_tasks(ignore_missing_welsh: true)).to be_empty
            end
          end

          context "when the optional Welsh task has been started but not completed" do
            let(:form) { build(:form, :live, :with_group, available_languages: %w[en cy], welsh_completed: false, group:) }

            it "returns no missing sections" do
              expect(task_status_service.all_incomplete_tasks(ignore_missing_welsh: true)).to be_empty
            end
          end
        end
      end
    end

    context "when a form is incomplete and should still be in draft state" do
      let(:form) { build(:form, :new_form, :with_group, group:) }

      it "returns a set of keys related to missing fields" do
        expect(task_status_service.all_incomplete_tasks).to match_array(%i[missing_pages missing_privacy_policy_url missing_contact_details missing_what_happens_next share_preview_not_completed missing_submission_email])
      end
    end
  end

  describe "#all_task_statuses" do
    let(:form) { create(:form, :live, :with_group, group:) }

    it "returns a hash with each of the task statuses" do
      expected_hash = {
        name_status: :completed,
        pages_status: :completed,
        declaration_status: :completed,
        what_happens_next_status: :completed,
        payment_link_status: :optional,
        brand_status: :optional,
        copy_of_answers_status: :optional,
        privacy_policy_status: :completed,
        support_contact_details_status: :completed,
        welsh_language_status: :optional,
        make_live_status: :completed,
        submission_attachments_status: :optional,
        batch_submissions_status: :optional,
        share_preview_status: :completed,
        submission_email_status: :completed,
        confirm_submission_email_status: :completed,
        make_only_english_live_status: :completed,
        make_only_welsh_live_status: :cannot_start,
      }
      expect(task_status_service.all_task_statuses).to eq expected_hash
    end

    context "when the form has a live Welsh version" do
      let(:form) { create(:form, :live_with_draft, :with_welsh_translation, welsh_completed: true) }

      context "and an incomplete welsh translation" do
        before do
          # Add new content requiring Welsh translation
          form.update!(declaration_markdown: "I declare this is correct", share_preview_completed: true)
        end

        it "make live_status is not_started" do
          expect(task_status_service.all_task_statuses).to include(make_live_status: :not_started)
        end
      end
    end

    context "when the form does not have a live Welsh version" do
      let(:form) { create(:form, :with_welsh_translation, welsh_completed: true) }

      context "and an incomplete welsh translation" do
        before do
          # Add new content requiring Welsh translation
          form.update!(declaration_markdown: "I declare this is correct", share_preview_completed: true)
        end

        it "make live_status is cannot_start" do
          expect(task_status_service.all_task_statuses).to include(make_live_status: :cannot_start)
        end
      end
    end
  end

  describe "#incomplete_email_tasks" do
    context "when mandatory tasks are complete" do
      let(:form) { create :form, :live }

      it "returns no incomplete tasks" do
        expect(task_status_service.incomplete_email_tasks).to be_empty
      end
    end

    context "when a form is incomplete and should still be in draft state" do
      let(:form) { create :form, :new_form }

      it "returns a set of keys related to missing fields" do
        expect(task_status_service.incomplete_email_tasks).to match_array(%i[missing_submission_email])
      end
    end
  end

  describe "#email_task_statuses" do
    let(:form) { create :form, :live }

    it "returns a hash with each of the email task statuses" do
      expected_hash = {
        submission_email_status: :completed,
        confirm_submission_email_status: :completed,
      }
      expect(task_status_service.email_task_statuses).to eq expected_hash
    end
  end
end
