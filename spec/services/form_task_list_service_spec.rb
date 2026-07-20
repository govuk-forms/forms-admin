require "rails_helper"

describe FormTaskListService do
  let(:current_user) { build(:user) }

  let(:organisation) { build :organisation, :with_signed_mou, id: 1 }
  let(:form) { create(:form, :new_form, pages:) }
  let(:pages) { [] }
  let(:group) { create(:group, name: "Group 1", organisation:, status: group_status, send_filler_answers_enabled:, custom_branding_enabled:) }
  let(:group_status) { :trial }
  let(:send_filler_answers_enabled) { true }
  let(:custom_branding_enabled) { true }

  let(:can_view_form) { true }
  let(:can_make_form_live) { false }
  let(:can_administer_group) { false }
  let(:upgrade) { false }

  before do
    form_policy = instance_double(FormPolicy,
                                  can_view_form?: can_view_form,
                                  can_make_form_live?: can_make_form_live,
                                  can_administer_group?: can_administer_group)
    allow(Pundit).to receive(:policy).with(current_user, form).and_return(form_policy)
    group_policy = instance_double(GroupPolicy,
                                   upgrade?: upgrade)
    allow(Pundit).to receive(:policy).with(current_user, kind_of(Group)).and_return(group_policy)
    GroupForm.create!(form_id: form.id, group_id: group.id)
  end

  describe ".task_counts" do
    let(:statuses) do
      {
        declaration_status: :completed,
        make_live_status: :not_started,
        name_status: :completed,
        pages_status: :completed,
        privacy_policy_status: :not_started,
        support_contact_details_status: :not_started,
        what_happens_next_status: :completed,
        payment_link_status: :optional,
        copy_of_answers_status: :optional,
        submission_attachments_status: :optional,
        batch_submissions_status: :optional,
        share_preview_status: :completed,
        submission_email_status: :completed,
        confirm_submission_email_status: :not_started,
      }
    end
    let(:form) { create(:form) }
    let(:task_status_service) { instance_double(TaskStatusService) }

    before do
      allow(TaskStatusService).to receive(:new).and_return(task_status_service)
      allow(task_status_service).to receive(:all_task_statuses).and_return(statuses)
    end

    context "when the user can make the form live" do
      let(:can_make_form_live) { true }

      it "returns counts of tasks" do
        result = described_class.new(form:, current_user:)

        expected_hash = { completed: 6, total: 10 }
        expect(result.task_counts).to eq expected_hash
      end
    end

    context "when the user cannot make the form live" do
      let(:can_make_form_live) { false }

      it "returns all statuses except for those inaccessible for users who cannot make forms live" do
        result = described_class.new(form:, current_user:)

        expected_hash = { completed: 5, total: 8 }

        expect(result.task_counts).to eq expected_hash
      end
    end
  end

  describe "#all_sections" do
    let(:all_sections) { described_class.call(form:, current_user:).all_sections }

    it "returns array of tasks objects for a given form" do
      expect(all_sections).to be_an_instance_of(Array)
    end

    it "returns 7 sections" do
      expect(all_sections.count).to eq 7
    end

    it "includes translations section" do
      section_titles = all_sections.map { |section| section[:title] }
      expect(section_titles).to include(I18n.t("forms.task_list_create.translations_section.title"))
    end

    it "has translations section before make form live section" do
      translations_section_index = all_sections.index { |section| section[:title] == I18n.t("forms.task_list_create.translations_section.title") }
      make_live_section_index = all_sections.index { |section| section[:title] == I18n.t("forms.task_list_create.make_form_live_section.title") }
      expect(translations_section_index).to be < make_live_section_index
    end

    describe "create form section tasks" do
      let(:section) do
        all_sections.first
      end

      let(:section_rows) { section[:rows] }

      it "has links to edit form name" do
        expect(section_rows.first[:task_name]).to eq "Edit the name of your form"
        expect(section_rows.first[:path]).to eq "/forms/#{form.id}/change-name"
      end

      it "has a link to add new pages/questions (if no pages/questions exist)" do
        expect(section_rows[1][:task_name]).to eq "Add and edit your questions"
        expect(section_rows[1][:path]).to eq "/forms/#{form.id}/pages/new/start-new-question"
      end

      context "when a page already exists" do
        let(:pages) { [build(:page)] }

        it "has a link to add/edit existing pages (if pages/questions exist)" do
          expect(section_rows[1][:task_name]).to eq "Add and edit your questions"
          expect(section_rows[1][:path]).to eq "/forms/#{form.id}/pages"
        end
      end

      it "has a link to add/edit declaration" do
        expect(section_rows[2][:task_name]).to eq "Add a declaration for people to agree to"
        expect(section_rows[2][:path]).to eq "/forms/#{form.id}/declaration"
      end

      it "has a link to add/edit 'What happens next'" do
        expect(section_rows[3][:task_name]).to eq "Add information about what happens next"
        expect(section_rows[3][:path]).to eq "/forms/#{form.id}/what-happens-next"
      end

      it "has the correct default statuses" do
        expect(section_rows.first[:status]).to eq :completed
        expect(section_rows[1][:status]).to eq :not_started
        expect(section_rows[2][:status]).to eq :not_started
        expect(section_rows[3][:status]).to eq :not_started
      end
    end

    describe "create form optional subsection tasks" do
      let(:section) do
        all_sections[1]
      end

      let(:section_rows) { section[:rows] }

      it "has link to payment link settings" do
        expect(section_rows.first[:task_name]).to eq "Add a link to a payment page on GOV.UK Pay"
        expect(section_rows.first[:path]).to eq "/forms/#{form.id}/payment-link"
      end

      context "when the custom_branding feature is enabled" do
        it "has link to brand settings" do
          expect(section_rows[1][:task_name]).to eq "Choose a brand for your form"
          expect(section_rows[1][:path]).to eq "/forms/#{form.id}/brand"
        end
      end

      context "when the custom_branding feature is disabled" do
        let(:custom_branding_enabled) { false }

        it "does not have link to brand settings" do
          expect(section_rows.map { |row| row[:path] }).not_to include("/forms/#{form.id}/brand")
        end
      end

      context "when the send_filler_answers feature is enabled" do
        it "has link to copy of answers settings" do
          expect(section_rows[2][:task_name]).to eq "Give people the option to ask for a copy of their answers"
          expect(section_rows[2][:path]).to eq "/forms/#{form.id}/copy-of-answers"
        end
      end

      context "when the send_filler_answers feature is disabled" do
        let(:send_filler_answers_enabled) { false }

        it "does not have link to copy of answers settings" do
          expect(section_rows.count).to eq 2
        end
      end
    end

    describe "how you get completed forms section tasks" do
      let(:section) do
        all_sections[2]
      end

      let(:section_rows) { section[:rows] }

      context "when submission_email is set" do
        before do
          form.submission_email = "test@example.gov.uk"
        end

        it "has link to set submission email" do
          expect(section_rows.first[:task_name]).to eq "Set the email address completed forms will be sent to"
          expect(section_rows.first[:path]).to eq "/forms/#{form.id}/submission-email"
        end

        it "has link to confirm submission email" do
          expect(section_rows[1][:task_name]).to eq "Enter the email address confirmation code"
          expect(section_rows[1][:path]).to eq "/forms/#{form.id}/confirm-submission-email"
        end

        it "has hint text explaining where completed forms will be sent to" do
          expect(section_rows.first[:hint_text]).to eq I18n.t("forms.task_list_create.how_you_get_completed_forms_section.hint_text_html", submission_email: form.submission_email)
        end

        it "has the correct default status" do
          expect(section_rows.first[:status]).to eq :completed
        end
      end

      context "when submission_email is not set" do
        it "has no hint text explaining where completed forms will be sent to" do
          expect(section_rows.first[:hint_text]).to be_nil
        end

        it "has the correct default status" do
          expect(section_rows.first[:status]).to eq :not_started
        end
      end

      context "and submission_email is set and no code sent" do
        before do
          form.submission_email = "test@example.gov.uk"
        end

        it "enter email has status of completed" do
          expect(section_rows.first[:status]).to eq :completed
        end

        it "enter code has status of completed" do
          expect(section_rows[1][:status]).to eq :completed
        end
      end

      context "and submission_email is not set and no code sent" do
        it "enter email has status of not_started" do
          expect(section_rows.first[:status]).to eq :not_started
        end

        it "enter code has status of cannot_start" do
          expect(section_rows[1][:status]).to eq :cannot_start
        end

        it "enter code is not active" do
          expect(section_rows[1][:active]).to be_falsy
        end
      end

      context "and submission_email is not set and code sent" do
        before do
          create :form_submission_email, form_id: form.id, confirmation_code: form.id
        end

        it "enter email has status of in_progress" do
          expect(section_rows.first[:status]).to eq :in_progress
        end

        it "enter code has status of incomplete" do
          expect(section_rows[1][:status]).to eq :not_started
        end

        it "enter code is active" do
          expect(section_rows[1][:active]).to be_truthy
        end
      end

      context "and submission_email is set and code blank" do
        before do
          form.submission_email = "test@example.gov.uk"
          create :form_submission_email, form_id: form.id, confirmation_code: nil
        end

        it "enter email has status of completed" do
          expect(section_rows.first[:status]).to eq :completed
        end

        it "enter code has status of completed" do
          expect(section_rows[1][:status]).to eq :completed
        end
      end
    end

    describe "how you get completed forms optional subsection tasks" do
      let(:section) do
        all_sections[3]
      end

      let(:section_rows) { section[:rows] }
      let(:all_task_names) { all_sections.flat_map { |section| section[:rows] }.compact.map { |row| row[:task_name] } }

      context "when the submission type is email" do
        it "has link to the submission attachments page" do
          expect(section_rows.first[:task_name]).to eq I18n.t("forms.task_list_create.how_you_get_completed_forms_section.optional_subsection.submission_attachments")
          expect(section_rows.first[:path]).to eq "/forms/#{form.id}/submission-attachments"
        end

        it "has the subsection title 'Optional tasks' as there are multiple tasks" do
          expect(section[:title]).to eq I18n.t("forms.task_list.optional_tasks_title.other")
        end
      end

      context "when the submission type is s3" do
        let(:form) { create(:form, submission_type: "s3") }

        it "does not have link to the submission attachments page" do
          expect(all_task_names).not_to include I18n.t("forms.task_list_create.how_you_get_completed_forms_section.optional_subsection.submission_attachments")
        end

        it "has the subsection title 'Optional task' as there is only one task" do
          expect(section[:title]).to eq I18n.t("forms.task_list.optional_tasks_title.one")
        end
      end

      it "has link to the batch submissions page" do
        expect(section_rows.second[:task_name]).to eq I18n.t("forms.task_list_create.how_you_get_completed_forms_section.optional_subsection.batch_submissions")
        expect(section_rows.second[:path]).to eq "/forms/#{form.id}/batch-submissions"
      end
    end

    describe "privacy and contact details tasks" do
      let(:section) do
        all_sections[4]
      end

      let(:section_rows) { section[:rows] }

      it "has link to set privacy policy url" do
        expect(section_rows.first[:task_name]).to eq "Provide a link to privacy information for this form"
        expect(section_rows.first[:path]).to eq "/forms/#{form.id}/privacy-policy"
      end

      it "has link to set contact details url" do
        expect(section_rows[1][:task_name]).to eq "Provide contact details for support"
        expect(section_rows[1][:path]).to eq "/forms/#{form.id}/contact-details"
      end

      it "has the correct default statuses" do
        expect(section_rows.first[:status]).to eq :not_started
        expect(section_rows[1][:status]).to eq :not_started
      end
    end

    describe "make form live section tasks" do
      let(:section) do
        all_sections[6]
      end

      let(:section_rows) { section[:rows] }
      let(:form) { create(:form, :ready_for_live) }

      context "when the form is in a trial group" do
        it "has no tasks" do
          expect(section).not_to include(:rows)
        end

        context "when the organisation has no organisation admins" do
          it "has text explaining that the form cannot be made live because it is in a trial group, with no link to request an upgrade" do
            expect(section[:body_text])
              .to eq I18n.t("forms.task_list_create.make_form_live_section.group_not_active.no_org_admin")
          end
        end

        context "when the organisation has an organisation admin" do
          before do
            create(:user, organisation:, role: :organisation_admin)
          end

          context "when the user is an editor" do
            it "has text explaining that the group must be upgraded, with a link to the group members page" do
              expect(section[:body_text])
                .to eq I18n.t(
                  "forms.task_list_create.make_form_live_section.group_not_active.group_editor.body_text", group_members_path: group_members_path(group)
                )
            end
          end

          context "when the user can administer the group" do
            let(:can_administer_group) { true }

            it "has text explaining that the group must be upgraded, with a link to the upgrade request page" do
              expect(section[:body_text])
                .to eq I18n.t(
                  "forms.task_list_create.make_form_live_section.group_not_active.group_admin.body_text", upgrade_path: request_upgrade_group_path(group)
                )
            end
          end

          context "when the user can directly upgrade the group" do
            let(:can_administer_group) { true }
            let(:upgrade) { true }

            it "has text explaining that forms need to be in an active group to be made live" do
              expect(section[:body_text])
                .to eq I18n.t(
                  "forms.task_list_create.make_form_live_section.group_not_active.group_admin.body_text", upgrade_path: group_path(group)
                )
            end
          end
        end
      end

      context "when the form is in an active group" do
        let(:group_status) { :active }

        context "and the user cannot administer the group" do
          it "has no tasks" do
            expect(section).not_to include(:rows)
          end

          it "has text explaining that group editors cannot make forms live" do
            expect(section[:body_text])
              .to eq I18n.t(
                "forms.task_list_create.make_form_live_section.user_cannot_administer.body_text",
                group_members_path: group_members_path(group),
              )
          end
        end
      end

      describe "share preview task" do
        context "when the user can make the form live" do
          let(:can_make_form_live) { true }

          context "when the form does not have any pages" do
            before do
              form.pages = []
            end

            it "has the correct task name" do
              expect(section_rows.first[:task_name]).to eq(I18n.t("forms.task_list_create.make_form_live_section.share_preview"))
            end

            it "is not active" do
              expect(section_rows.first[:active]).to be false
            end
          end

          context "when the form has at least one page" do
            let(:pages) { [build(:page)] }

            it "has the correct task name" do
              expect(section_rows.first[:task_name]).to eq(I18n.t("forms.task_list_create.make_form_live_section.share_preview"))
            end

            it "is active" do
              expect(section_rows.first[:active]).to be true
            end

            it "has a link to the share preview task" do
              expect(section_rows.first[:path]).to eq(share_preview_path(form.id))
            end
          end
        end
      end

      describe "make live task" do
        context "when the form is in an active group" do
          let(:group_status) { :active }

          context "and the user can administer the group" do
            let(:can_make_form_live) { true }
            let(:can_administer_group) { true }

            it "has link to make the form live" do
              expect(section_rows.second[:task_name]).to eq "Make your form live"
              expect(section_rows.second[:path]).to eq "/forms/#{form.id}/make-live"
            end

            context "when form is ready to make live" do
              let(:form) { create(:form, :ready_for_live) }

              it "has link to make the form live" do
                expect(section_rows.second[:task_name]).to eq "Make your form live"
                expect(section_rows.second[:path]).to eq "/forms/#{form.id}/make-live"
              end

              it "has the correct default status" do
                expect(section_rows.second[:status]).to eq :not_started
              end

              context "when the form has Welsh translations" do
                let(:form) { create(:form, :ready_for_live, :with_welsh_translation, welsh_completed: false) }

                it "has a link to make the English form live" do
                  expect(section_rows.second[:task_name]).to eq I18n.t("forms.task_list_create.make_form_live_section.make_english_form_live")
                  expect(section_rows.second[:path]).to eq "/forms/#{form.id}/make-live/en"
                  expect(section_rows.second[:status]).to eq :not_started
                end

                it "has the make Welsh live task without a link" do
                  expect(section_rows.third[:task_name]).to eq I18n.t("forms.task_list_create.make_form_live_section.make_welsh_form_live")
                  expect(section_rows.third[:path]).to eq ""
                  expect(section_rows.third[:status]).to eq :cannot_start
                end
              end
            end

            context "when form is live" do
              before do
                allow(form).to receive_messages(is_live?: true, has_live_version: true)
              end

              it "has tasks" do
                expect(section_rows).not_to be_empty
              end

              it "describes the section title correctly" do
                expect(section[:title]).to eq I18n.t("forms.task_list_edit.make_form_live_section.make_live")
              end

              it "describes the task correctly" do
                expect(section_rows.second[:task_name]).to eq I18n.t("forms.task_list_edit.make_form_live_section.make_live")
              end

              context "when the form has a draft with welsh translations" do
                before do
                  allow(form).to receive(:has_welsh_translation?).and_return(true)
                end

                context "when the form has English changes that are not yet live" do
                  before do
                    allow(form).to receive(:changed_from_live_version?).with(language: "en").and_return(true)
                  end

                  it "has a link to make the English form live" do
                    expect(section_rows.second[:task_name]).to eq I18n.t("forms.task_list_edit.make_form_live_section.make_english_form_live")
                    expect(section_rows.second[:path]).to eq "/forms/#{form.id}/make-live/en"
                    expect(section_rows.second[:status]).to eq :not_started
                  end

                  it "has the make Welsh live task without a link" do
                    expect(section_rows.third[:task_name]).to eq I18n.t("forms.task_list_create.make_form_live_section.make_welsh_form_live")
                    expect(section_rows.third[:path]).to eq ""
                    expect(section_rows.third[:status]).to eq :cannot_start
                  end

                  context "when the Welsh version can be made live" do
                    before do
                      allow(form).to receive(:can_make_language_live?).with(language: "en").and_return(true)
                      allow(form).to receive(:can_make_language_live?).with(language: "cy").and_return(true)
                    end

                    it "has a link to make the Welsh form live" do
                      expect(section_rows.third[:task_name]).to eq "Make your Welsh form live"
                      expect(section_rows.third[:path]).to eq "/forms/#{form.id}/make-live/cy"
                      expect(section_rows.third[:status]).to eq :not_started
                    end
                  end
                end

                context "when the form has no draft English changes" do
                  before do
                    allow(form).to receive(:changed_from_live_version?).with(language: "en").and_return(false)
                  end

                  it "has the make English live task without a link" do
                    expect(section_rows.second[:task_name]).to eq I18n.t("forms.task_list_create.make_form_live_section.make_english_form_live")
                    expect(section_rows.second[:path]).to eq ""
                    expect(section_rows.second[:status]).to eq :completed
                  end

                  it "has the make Welsh live task without a link" do
                    expect(section_rows.third[:task_name]).to eq I18n.t("forms.task_list_create.make_form_live_section.make_welsh_form_live")
                    expect(section_rows.third[:path]).to eq ""
                    expect(section_rows.third[:status]).to eq :cannot_start
                  end

                  context "when the Welsh version can be made live" do
                    before do
                      allow(form).to receive(:can_make_language_live?).with(language: "en").and_return(true)
                      allow(form).to receive(:can_make_language_live?).with(language: "cy").and_return(true)
                    end

                    it "has a link to make the Welsh form live" do
                      expect(section_rows.third[:task_name]).to eq "Make your Welsh form live"
                      expect(section_rows.third[:path]).to eq "/forms/#{form.id}/make-live/cy"
                      expect(section_rows.third[:status]).to eq :not_started
                    end
                  end
                end
              end
            end

            context "when the form is archived" do
              let(:form) { create(:form, :archived) }

              it "has link to make the form live" do
                expect(section_rows.second[:task_name]).to eq "Make your form live"
                expect(section_rows.second[:path]).to eq "/forms/#{form.id}/make-live"
              end

              context "when the form has a draft with welsh translations" do
                let(:form) { create(:form, :archived_with_draft) }

                before do
                  allow(form).to receive(:has_welsh_translation?).and_return(true)
                end

                it "has a link to make the English form live" do
                  expect(section_rows.second[:task_name]).to eq I18n.t("forms.task_list_create.make_form_live_section.make_english_form_live")
                  expect(section_rows.second[:path]).to eq "/forms/#{form.id}/make-live/en"
                  expect(section_rows.second[:status]).to eq :not_started
                end

                it "has the make Welsh live task without a link" do
                  expect(section_rows.third[:task_name]).to eq I18n.t("forms.task_list_create.make_form_live_section.make_welsh_form_live")
                  expect(section_rows.third[:path]).to eq ""
                  expect(section_rows.third[:status]).to eq :cannot_start
                end
              end
            end
          end
        end
      end
    end

    context "when editing an existing form" do
      let(:form) { create(:form, :live) }
      let(:can_make_form_live) { true }

      it "has the expected section titles" do
        section_titles = all_sections.map { |section| section[:title] }
        expect(section_titles).to contain_exactly(
          I18n.t("forms.task_list_edit.create_form_section.title"),
          I18n.t("forms.task_list.optional_tasks_title.other"),
          I18n.t("forms.task_list_edit.how_you_get_completed_forms_section.title"),
          I18n.t("forms.task_list.optional_tasks_title.other"),
          I18n.t("forms.task_list_edit.privacy_and_contact_details_section.title"),
          I18n.t("forms.task_list_edit.translations_section.title"),
          I18n.t("forms.task_list_edit.make_form_live_section.make_live"),
        )
      end

      it "has the expected task names" do
        task_names = all_sections.flat_map { |section| section[:rows] }.compact.map { |row| row[:task_name] }
        expect(task_names).to contain_exactly(
          I18n.t("forms.task_list_edit.create_form_section.name"),
          I18n.t("forms.task_list_edit.create_form_section.questions"),
          I18n.t("forms.task_list_edit.create_form_section.declaration"),
          I18n.t("forms.task_list_edit.create_form_section.what_happens_next"),
          I18n.t("forms.task_list_edit.create_form_optional_subsection.payment_link"),
          I18n.t("forms.task_list_edit.create_form_optional_subsection.brand"),
          I18n.t("forms.task_list_edit.create_form_optional_subsection.copy_of_answers"),
          I18n.t("forms.task_list_edit.how_you_get_completed_forms_section.email"),
          I18n.t("forms.task_list_edit.how_you_get_completed_forms_section.confirm_email"),
          I18n.t("forms.task_list_edit.how_you_get_completed_forms_section.optional_subsection.submission_attachments"),
          I18n.t("forms.task_list_edit.how_you_get_completed_forms_section.optional_subsection.batch_submissions"),
          I18n.t("forms.task_list_edit.privacy_and_contact_details_section.privacy_policy"),
          I18n.t("forms.task_list_edit.privacy_and_contact_details_section.contact_details"),
          I18n.t("forms.task_list_edit.translations_section.add_welsh"),
          I18n.t("forms.task_list_edit.make_form_live_section.share_preview"),
          I18n.t("forms.task_list_edit.make_form_live_section.make_live"),
        )
      end
    end
  end
end
