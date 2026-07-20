require "rails_helper"

RSpec.describe Form, type: :model do
  subject(:form) { described_class.new }

  let(:current_user) { build :user }

  describe "factory" do
    it "has a valid factory" do
      form = create :form
      expect(form).to be_valid
    end

    it "has a live trait" do
      form = build :form, :live
      expect(form.state).to eq "live"
    end

    it "has a live with draft trait" do
      form = build :form, :live_with_draft
      expect(form.state).to eq "live_with_draft"
    end

    it "has an archived trait" do
      form = build :form, :archived
      expect(form.state).to eq "archived"
    end

    it "has an archived with draft trait" do
      form = build :form, :archived_with_draft
      expect(form.state).to eq "archived_with_draft"
    end

    it "has a ready for routing trait" do
      form = create :form, :ready_for_routing
      expect(form.pages).to be_present
      expect(form.pages.map(&:position)).to eq [1, 2, 3, 4, 5]
    end

    describe "task status traits" do
      before do
        form.set_task_status_service(TaskStatusService.new(form:, current_user:))
      end

      describe "ready for live trait" do
        let(:form) { build :form, :ready_for_live, :with_group }

        it "creates a form that is ready to be made live" do
          expect(form.all_ready_for_live?).to be true
          expect(form.all_incomplete_tasks).to be_empty
          expect(form.all_task_statuses).to include(
            declaration_status: :completed,
            make_live_status: :not_started,
            name_status: :completed,
            pages_status: :completed,
            privacy_policy_status: :completed,
            support_contact_details_status: :completed,
            what_happens_next_status: :completed,
          )
        end
      end

      describe "missing pages trait" do
        let(:form) { build :form, :missing_pages }

        it "creates a form with missing pages" do
          expect(form.all_incomplete_tasks).to eq %i[missing_pages]
        end
      end
    end
  end

  describe "validations" do
    it "validates" do
      form.name = "test"
      expect(form).to be_valid
    end

    it "requires name" do
      expect(form).to be_invalid
      expect(form.errors[:name]).to include("can't be blank")
    end

    it "requires available languages" do
      form.available_languages = ""

      expect(form).to be_invalid
      expect(form.errors[:available_languages]).to include("can't be blank")

      form.available_languages = []

      expect(form).to be_invalid
      expect(form.errors[:available_languages]).to include("can't be blank")
    end

    it "disallows invalid available languages" do
      form.available_languages = %w[cn jp]

      expect(form).to be_invalid
      expect(form.errors[:available_languages]).to include("is not included in the list")
    end

    it "allows en and cy" do
      form.name = "test"
      form.available_languages = %w[en cy]

      expect(form).to be_valid
      expect(form.errors[:available_languages]).to be_empty
    end

    it "allows cy only" do
      form.name = "prawf"
      form.available_languages = %w[cy]

      expect(form).to be_valid
      expect(form.errors[:available_languages]).to be_empty
    end

    it "allows en only" do
      form.name = "test"
      form.available_languages = %w[en]

      expect(form).to be_valid
      expect(form.errors[:available_languages]).to be_empty
    end

    context "when submission_email contains multiple email addresses" do
      it "is invalid with comma-separated email addresses" do
        form.name = "test"
        form.submission_email = "first@example.gov.uk,second@example.gov.uk"
        expect(form).to be_invalid
      end

      it "is invalid with semi-colon-separated email addresses" do
        form.name = "test"
        form.submission_email = "first@example.gov.uk;second@example.gov.uk"
        expect(form).to be_invalid
      end

      it "is invalid with comma-separated email addresses with spaces" do
        form.name = "test"
        form.submission_email = "first@example.gov.uk, second@example.gov.uk"
        expect(form).to be_invalid
      end

      it "is invalid with semi-colon-separated email addresses with spaces" do
        form.name = "test"
        form.submission_email = "first@example.gov.uk; second@example.gov.uk"
        expect(form).to be_invalid
      end

      it "is valid with a single email address" do
        form.name = "test"
        form.submission_email = "single@example.gov.uk"
        expect(form).to be_valid
      end
    end

    context "when support_email contains multiple email addresses" do
      it "is invalid with comma-separated email addresses" do
        form.name = "test"
        form.support_email = "first@example.gov.uk,second@example.gov.uk"
        expect(form).to be_invalid
      end

      it "is invalid with semi-colon-separated email addresses" do
        form.name = "test"
        form.support_email = "first@example.gov.uk;second@example.gov.uk"
        expect(form).to be_invalid
      end

      it "is invalid with comma-separated email addresses with spaces" do
        form.name = "test"
        form.support_email = "first@example.gov.uk, second@example.gov.uk"
        expect(form).to be_invalid
      end

      it "is invalid with semi-colon-separated email addresses with spaces" do
        form.name = "test"
        form.support_email = "first@example.gov.uk; second@example.gov.uk"
        expect(form).to be_invalid
      end

      it "is valid with a single email address" do
        form.name = "test"
        form.support_email = "single@example.gov.uk"
        expect(form).to be_valid
      end
    end

    context "when the form has validation errors" do
      let(:form) { create :form, pages: [routing_page, goto_page] }
      let(:routing_page) do
        new_routing_page = create :page
        new_routing_page.routing_conditions = [create(:condition, routing_page_id: new_routing_page.id, goto_page_id: nil)]
        new_routing_page
      end
      let(:goto_page) { create :page }
      let(:goto_page_id) { goto_page.id }

      context "when the form is marked complete" do
        it "returns invalid" do
          form.question_section_completed = true

          expect(form).to be_invalid
          expect(form.errors[:base]).to include("Form has routing validation errors")
        end
      end

      context "when the form is not marked complete" do
        it "returns valid" do
          form.question_section_completed = false
          expect(form).to be_valid
        end
      end

      context "when the payment url is not a url" do
        it "returns invalid" do
          form.payment_url = "not a url"
          expect(form).to be_invalid
        end
      end

      context "when the payment url is a url" do
        it "returns valid" do
          form.payment_url = "https://example.com/"
          expect(form).to be_valid
        end
      end

      context "when there is no payment url" do
        it "returns valid" do
          form.payment_url = nil
          expect(form).to be_valid
        end
      end

      context "when there is no submission type" do
        it "returns invalid" do
          form.submission_type = nil
          expect(form).to be_invalid
        end
      end
    end
  end

  describe "form_slug" do
    it "is set when the form is created" do
      form = described_class.create!(name: "Apply for a license to test forms")
      expect(form.form_slug).to eq("apply-for-a-license-to-test-forms")
    end

    it "updates when name is changed" do
      form.name = "Apply for a license to test forms"
      expect(form.name).to eq("Apply for a license to test forms")
      expect(form.form_slug).to eq("apply-for-a-license-to-test-forms")
    end

    it "is blank if the name is blank" do
      form.name = ""
      expect(form.form_slug).to eq("")
    end

    it "setting form slug directly doesn't change it" do
      form.name = "Apply for a license to test forms"
      form.form_slug = "something totally different"
      expect(form.form_slug).to eq("apply-for-a-license-to-test-forms")
    end
  end

  describe "translations" do
    let(:form) { create(:form) }

    let(:translated_attributes) do
      %i[
        privacy_policy_url
        support_email
        support_phone
        support_url
        support_url_text
        declaration_markdown
        what_happens_next_markdown
      ]
    end

    it "can set and read translated attributes for :en and :cy locales" do
      Mobility.with_locale(:en) do
        form.name = "English Name"
        form.payment_url = "https://example.gov.uk/en"
        translated_attributes.each do |attribute|
          value = attribute == :support_email ? "english@example.gov.uk" : "english_#{attribute}"
          form.send("#{attribute}=", value)
        end
        form.save!
      end

      Mobility.with_locale(:cy) do
        form.name = "Welsh Name"
        form.payment_url = "https://example.gov.uk/cy"
        translated_attributes.each do |attribute|
          value = attribute == :support_email ? "welsh@example.gov.uk" : "welsh_#{attribute}"
          form.send("#{attribute}=", value)
        end
        form.save!
      end

      Mobility.with_locale(:en) do
        form.reload
        expect(form.name).to eq("English Name")
        expect(form.form_slug).to eq("english-name")
        expect(form.payment_url).to eq("https://example.gov.uk/en")
        translated_attributes.each do |attribute|
          expected_value = attribute == :support_email ? "english@example.gov.uk" : "english_#{attribute}"
          expect(form.send(attribute)).to eq(expected_value)
        end
      end

      Mobility.with_locale(:cy) do
        form.reload
        expect(form.name).to eq("Welsh Name")
        expect(form.form_slug).to eq("english-name")
        expect(form.payment_url).to eq("https://example.gov.uk/cy")
        translated_attributes.each do |attribute|
          expected_value = attribute == :support_email ? "welsh@example.gov.uk" : "welsh_#{attribute}"
          expect(form.send(attribute)).to eq(expected_value)
        end
      end
    end
  end

  describe "external_id" do
    it "intialises a new form with an external id matching its id" do
      form = create :form
      expect(form.external_id).to eq(form.id.to_s)
    end
  end

  describe "update_draft_form_document" do
    let(:form) { create :form }

    it "calls FormDocumentSyncService to update the draft Form" do
      sync_service_instance = instance_double(FormDocumentSyncService)
      allow(FormDocumentSyncService).to receive(:new).with(form).and_return(sync_service_instance)
      expect(sync_service_instance).to receive(:update_draft_form_document)

      form.update!(name: "new name")
    end
  end

  describe "page scope" do
    it "returns pages in position order" do
      form = create :form

      page_a = create :page, form_id: form.id, position: 2
      page_b = create :page, form_id: form.id, position: 1

      expect(form.reload.pages).to eq([page_b, page_a])
    end
  end

  describe "live_form_document" do
    context "when there is no live form document" do
      it "returns nil" do
        expect(form.live_form_document).to be_nil
      end
    end

    context "when there is a live form document" do
      subject(:form) { create :form, :live }

      it "returns the live form document" do
        expect(form.live_form_document).to be_a(FormDocument)
      end
    end

    context "when there only an archived form document" do
      subject(:form) { create :form, :archived }

      it "returns nil" do
        expect(form.live_form_document).to be_nil
      end
    end
  end

  describe "live_welsh_form_document" do
    context "when there is no live Welsh form document" do
      subject(:form) { create :form, :live }

      it "returns nil" do
        expect(form.live_welsh_form_document).to be_nil
      end
    end

    context "when there is a live Welsh form document" do
      subject(:form) { create :form, :live, :with_welsh_translation }

      it "returns the live form document" do
        expect(form.live_welsh_form_document).to be_a(FormDocument)
      end
    end

    context "when there only an archived Welsh form document" do
      subject(:form) { create :form, :archived, :with_welsh_translation }

      it "returns nil" do
        expect(form.live_welsh_form_document).to be_nil
      end
    end
  end

  describe "archived_form_document" do
    context "when there is no archived form document" do
      it "returns nil" do
        expect(form.archived_form_document).to be_nil
      end
    end

    context "when there is an archived form document" do
      subject(:form) { create :form, :archived }

      it "returns nil" do
        expect(form.archived_form_document).to be_a(FormDocument)
      end
    end

    context "when there is only a live form document" do
      subject(:form) { create :form, :live }

      it "returns nil" do
        expect(form.archived_form_document).to be_nil
      end
    end
  end

  describe "archived_welsh_form_document" do
    context "when there is no archived Welsh form document" do
      subject(:form) { create :form, :archived }

      it "returns nil" do
        expect(form.archived_welsh_form_document).to be_nil
      end
    end

    context "when there is an archived Welsh form document" do
      subject(:form) { create :form, :archived, :with_welsh_translation }

      it "returns nil" do
        expect(form.archived_welsh_form_document).to be_a(FormDocument)
      end
    end

    context "when there is only a live Welsh form document" do
      subject(:form) { create :form, :live, :with_welsh_translation }

      it "returns nil" do
        expect(form.archived_welsh_form_document).to be_nil
      end
    end
  end

  describe "draft_welsh_form_document" do
    context "when there is no draft Welsh form document" do
      subject(:form) { create :form }

      it "returns nil" do
        expect(form.draft_welsh_form_document).to be_nil
      end
    end

    context "when there is a draft Welsh form document" do
      subject(:form) { create :form, :draft, :with_welsh_translation }

      it "returns nil" do
        expect(form.draft_welsh_form_document).to be_a(FormDocument)
      end
    end

    context "when there is only a live Welsh form document" do
      subject(:form) { create :form, :live, :with_welsh_translation }

      before do
        FormDocument.find_by(form:, tag: "draft", language: "cy").destroy
      end

      it "returns nil" do
        expect(form.draft_welsh_form_document).to be_nil
      end
    end
  end

  describe "draft_form_document" do
    context "when there is no archived form document" do
      it "returns nil" do
        expect(form.draft_form_document).to be_nil
      end
    end

    context "when there is an draft form document" do
      subject(:form) { create :form, :draft }

      it "returns nil" do
        expect(form.draft_form_document).to be_a(FormDocument)
      end
    end

    context "when there is only a live form document" do
      subject(:form) { create :form, :live }

      before do
        FormDocument.find_by(form:, tag: "draft").destroy
      end

      it "returns nil" do
        expect(form.draft_form_document).to be_nil
      end
    end
  end

  describe "FormStateMachine" do
    before do
      form.set_task_status_service(TaskStatusService.new(form:, current_user:))
    end

    describe "#make_live!" do
      let(:form) { create :form, :ready_for_live }

      it "calls FormDocumentSyncService" do
        sync_service_instance = instance_double(FormDocumentSyncService)
        allow(FormDocumentSyncService).to receive(:new).with(form).and_return(sync_service_instance)
        expect(sync_service_instance).to receive(:synchronize_live_form)
        expect(sync_service_instance).to receive(:update_draft_form_document)
        form.make_live!
      end

      it "creates a live form document" do
        expect { form.make_live! }.to change { form.reload.live_form_document }.from(nil)
      end

      context "when first_made_live_at is not already set" do
        it "sets first_made_live_at" do
          freeze_time do
            expect { form.make_live! }.to change { form.reload.first_made_live_at }.from(nil).to(Time.zone.now)
            expect(form.first_made_live_at).to eq(form.updated_at)
          end
        end

        it "populates first_made_live_at in the live FormDocument" do
          freeze_time do
            form.make_live!
            expect(form.reload.live_form_document.reload.content["first_made_live_at"]).to eq(Time.zone.now.iso8601(6))
          end
        end

        it "populates first_made_live_at in the draft FormDocument" do
          freeze_time do
            form.make_live!
            expect(form.reload.draft_form_document.reload.content["first_made_live_at"]).to eq(Time.zone.now.iso8601(6))
          end
        end
      end

      context "when first_made_live_at is already set" do
        let(:form) { create :form, :live_with_draft }

        it "does no update the first_made_live_at" do
          expect { form.make_live! }.not_to(change { form.reload.first_made_live_at })
        end
      end
    end

    describe "#archive_live_form!" do
      let(:form) { create :form, :live }

      it "calls FormDocumentSyncService" do
        sync_service_instance = instance_double(FormDocumentSyncService)
        allow(FormDocumentSyncService).to receive(:new).with(form).and_return(sync_service_instance)
        expect(sync_service_instance).to receive(:synchronize_archived_form)
        expect(sync_service_instance).to receive(:update_draft_form_document)

        form.archive_live_form!
      end

      it "creates a archived form document" do
        expect { form.archive_live_form! }.to change { form.reload.archived_form_document }.from(nil)
      end
    end

    describe "#create_draft_from_live_form!" do
      let(:form) { create :form, :live }

      it "sets share_preview_completed to false" do
        expect { form.create_draft_from_live_form! }.to change { form.reload.share_preview_completed }.to(false)
      end
    end

    describe "#create_draft_from_archived_form!" do
      let(:form) { create :form, :archived }

      it "sets share_preview_completed to false" do
        expect { form.create_draft_from_archived_form! }.to change { form.reload.share_preview_completed }.to(false)
      end
    end
  end

  describe "#save_question_changes!" do
    let(:form) { create :form, question_section_completed: true }

    it "saves the form" do
      form.name = "new name"

      expect {
        form.save_question_changes!
      }.to change { described_class.find(form.id).name }.to("new name")
    end

    it "updates the question section completed to false" do
      expect {
        form.save_question_changes!
      }.to change { form.reload.question_section_completed }.to(false)
    end

    context "when the form is draft" do
      it "does not change the form's state" do
        expect {
          form.save_question_changes!
        }.not_to(change { form.reload.state })
      end
    end

    context "when the form is live" do
      let(:form) { create(:form, :live) }

      it "changes the form's state to live_with_draft" do
        expect {
          form.save_question_changes!
        }.to change { form.reload.state }.to("live_with_draft")
      end
    end

    context "when the form is archived" do
      let(:form) { create(:form, :archived) }

      it "changes the form's state to archived_with_draft" do
        expect {
          form.save_question_changes!
        }.to change { form.reload.state }.to("archived_with_draft")
      end
    end

    context "when no attributes on the form will be changed" do
      let(:form) { create :form, question_section_completed: false }

      it "still changes the form's updated_at" do
        expect {
          form.save_question_changes!
        }.to(change { form.reload.updated_at })
      end

      it "changes the form_document's updated at" do
        expect {
          form.save_question_changes!
        }.to(change { form.reload.draft_form_document.content["updated_at"] })
      end
    end
  end

  describe "#save_draft!" do
    shared_examples "#save_draft!" do
      context "when the form has valid unsaved changes" do
        before do
          form.name = "new name"
        end

        it "returns true" do
          expect(form.save_draft!).to be true
        end

        it "saves the form" do
          expect {
            form.save_draft!
          }.to change { described_class.find(form.id).name }.to("new name")
        end

        it "updates the draft form document" do
          expect {
            form.name = "new name"
            form.save_draft!
          }.to change { form.reload.draft_form_document.content["name"] }.to("new name")
        end

        it "updates previous_changes" do
          form.name = "new name"

          expect {
            form.save_draft!
          }.to change(form, :previous_changes).to(a_hash_including("name" => ["old name", "new name"]))
        end
      end

      context "when the form has invalid unsaved changes" do
        before do
          form.name = ""
        end

        it "raises an error" do
          expect { form.save_draft! }.to raise_error ActiveRecord::RecordInvalid
        end

        it "does not save the form" do
          expect {
            expect { form.save_draft! }.to raise_error ActiveRecord::RecordInvalid
          }.not_to(change { described_class.find(form.id).name })
        end

        it "does not update the draft form document" do
          expect {
            form.name = ""
            expect { form.save_draft! }.to raise_error ActiveRecord::RecordInvalid
          }.not_to(change { form.reload.draft_form_document.content["name"] })
        end

        it "does not change share_preview_completed" do
          expected = form.share_preview_completed
          expect { form.save_draft! }.to raise_error ActiveRecord::RecordInvalid
          expect(form.share_preview_completed).to be expected
          expect(form.reload.share_preview_completed).to be expected
        end
      end
    end

    context "when the form is draft" do
      let(:form) { create :form, name: "old name" }

      include_examples "#save_draft!"

      it "does not change the form's state" do
        expect {
          form.save_draft!
        }.not_to(change { form.reload.state })
      end

      context "when share_preview_completed is true" do
        let(:form) { create :form, :ready_for_live }

        it "does not set share_preview_completed to false" do
          form.save_draft!
          expect(form.share_preview_completed).not_to be false
          expect(form.reload.share_preview_completed).not_to be false
        end
      end
    end

    context "when the form is live" do
      let(:form) { create(:form, :live, name: "old name") }

      include_examples "#save_draft!"

      it "changes the form's state to live_with_draft" do
        expect {
          form.save_draft!
        }.to change { form.reload.state }.to("live_with_draft")
      end

      it "sets share_preview_completed to false" do
        form.save_draft!
        expect(form.share_preview_completed).to be false
        expect(form.reload.share_preview_completed).to be false
      end
    end

    context "when the form is archived" do
      let(:form) { create(:form, :archived, name: "old name") }

      include_examples "#save_draft!"

      it "changes the form's state to archived_with_draft" do
        expect {
          form.save_draft!
        }.to change { form.reload.state }.to("archived_with_draft")
      end

      it "sets share_preview_completed to false" do
        form.save_draft!
        expect(form.share_preview_completed).to be false
        expect(form.reload.share_preview_completed).to be false
      end
    end
  end

  describe "#has_draft_version" do
    let(:live_form) { create(:form, :live) }
    let(:new_form) { create(:form) }

    it "returns true if form is draft" do
      new_form.state = :draft
      expect(new_form.has_draft_version).to be(true)
    end

    it "returns false if form is live and no edits" do
      live_form.state = :live
      expect(live_form.has_draft_version).to be(false)
    end

    it "returns true if form is live with a draft" do
      live_form.state = :live_with_draft
      live_form.update!(name: "Form (edited)")

      expect(live_form.has_draft_version).to be(true)
    end

    it "returns true if form has been made live and one of its pages has been edited" do
      live_form.pages[0].question_text = "Edited question"
      live_form.pages[0].save_and_update_form

      expect(live_form.has_draft_version).to be(true)
    end

    it "returns true if form is archived with a draft" do
      live_form.state = :archived_with_draft

      expect(live_form.has_draft_version).to be(true)
    end
  end

  describe "#has_live_version" do
    let(:live_form) { create(:form, :live) }
    let(:new_form) { create(:form) }

    it "returns false if form has not been made live before" do
      expect(new_form.has_live_version).to be(false)
    end

    it "returns true if form has been made live" do
      expect(live_form.has_live_version).to be(true)
    end
  end

  describe "#has_been_archived" do
    let(:live_form) { create(:form, :live) }
    let(:archived_form) { create(:form, state: :archived) }
    let(:archived_with_draft_form) { create(:form, state: :archived_with_draft) }

    it "returns false if form is live" do
      expect(live_form.has_been_archived).to be(false)
    end

    it "returns true if form has been archived" do
      expect(archived_form.has_been_archived).to be(true)
    end

    it "returns true if form has been archived with draft" do
      expect(archived_with_draft_form.has_been_archived).to be(true)
    end
  end

  describe "#has_routing_errors" do
    let(:form) { create :form, pages: [routing_page, goto_page] }
    let(:routing_page) do
      new_routing_page = create :page
      new_routing_page.routing_conditions = [create(:condition, routing_page_id: new_routing_page.id, goto_page_id:)]
      new_routing_page
    end
    let(:goto_page) { create :page }
    let(:goto_page_id) { goto_page.id }

    context "when there are no validation errors" do
      it "returns false" do
        expect(form.has_routing_errors).to be false
      end
    end

    context "when there are validation errors" do
      let(:goto_page_id) { nil }

      it "returns true" do
        expect(form.has_routing_errors).to be true
      end
    end
  end

  describe "#all_incomplete_tasks" do
    before do
      form.set_task_status_service(TaskStatusService.new(form:, current_user:))
    end

    context "when a form is complete and ready to be made live" do
      let(:form) { build :form, :live }

      it "returns no missing sections" do
        expect(form.all_incomplete_tasks).to be_empty
      end
    end

    context "when a form is incomplete and should still be in draft state" do
      let(:form) { build :form, :new_form }

      it "returns a set of keys related to missing fields" do
        expect(form.all_incomplete_tasks).to match_array(%i[missing_pages missing_submission_email missing_privacy_policy_url missing_contact_details missing_what_happens_next share_preview_not_completed])
      end
    end
  end

  describe "submission type" do
    describe "enum" do
      it "returns a list of submission types" do
        expect(described_class.submission_types.keys).to eq(%w[email s3])
        expect(described_class.submission_types.values).to eq(%w[email s3])
      end
    end
  end

  describe "answer email copy" do
    describe "enum" do
      it "returns a list of email copy answers values" do
        expect(described_class.send_copy_of_answers.keys).to eq(%w[disabled enabled])
        expect(described_class.send_copy_of_answers.values).to eq(%w[disabled enabled])
      end
    end

    it "defaults to disabled" do
      form = build(:form)
      expect(form.send_copy_of_answers).to eq("disabled")
      expect(form.send_copy_of_answers_disabled?).to be true
    end
  end

  describe "submission format" do
    let(:form) { create :form }

    it "can be empty" do
      form.update!(submission_format: [])
      expect(form.submission_format).to be_empty
    end

    it "stores an array of strings" do
      form.update!(submission_format: %w[csv json])
      expect(form.submission_format).to include "csv"
      expect(form.submission_format).to include "json"
    end

    # ActiveRecord doesn't support enums with arrays
    # describe "enum" do
    #   it "returns a list of submission formats" do
    #     formats = %w[csv json]
    #     expect(described_class.submission_formats.keys).to eq formats
    #     expect(described_class.submission_formats.values).to eq formats
    #   end
    # end
  end

  describe "#destroy" do
    let(:form) { create :form }

    context "when form is in a group" do
      let(:form) { create :form }

      before do
        group = create :group
        GroupForm.create!(group:, form:)
      end

      it "destroys the GroupForm" do
        expect {
          form.destroy
        }.to change(GroupForm, :count).by(-1)

        expect(GroupForm.find_by(form_id: form.id)).to be_nil
      end
    end
  end

  describe "#all_ready_for_live?" do
    before do
      task_status_service = instance_double(TaskStatusService)
      allow(TaskStatusService).to receive(:new).and_return(task_status_service)
      allow(task_status_service).to receive(:mandatory_tasks_completed?).and_return(mandatory_tasks_completed)

      form.set_task_status_service(task_status_service)
    end

    context "when not all mandatory tasks have been completed" do
      let(:mandatory_tasks_completed) { false }

      it "returns false" do
        expect(form.all_ready_for_live?).to be false
      end
    end

    context "when all mandatory tasks have been completed" do
      let(:mandatory_tasks_completed) { true }

      it "returns true" do
        expect(form.all_ready_for_live?).to be true
      end
    end
  end

  describe "#all_task_statuses" do
    let(:group) { create :group }
    let(:form) { build :form, :live, :with_group, group: }

    before do
      form.set_task_status_service(TaskStatusService.new(form:, current_user:))
    end

    it "returns a hash with each of the task statuses" do
      expected_hash = {
        name_status: :completed,
        pages_status: :completed,
        declaration_status: :completed,
        what_happens_next_status: :completed,
        submission_email_status: :completed,
        confirm_submission_email_status: :completed,
        privacy_policy_status: :completed,
        payment_link_status: :optional,
        brand_status: :optional,
        copy_of_answers_status: :optional,
        submission_attachments_status: :optional,
        batch_submissions_status: :optional,
        support_contact_details_status: :completed,
        welsh_language_status: :optional,
        share_preview_status: :completed,
        make_live_status: :completed,
        make_only_english_live_status: :completed,
        make_only_welsh_live_status: :cannot_start,
      }
      expect(form.all_task_statuses).to eq expected_hash
    end
  end

  describe "#page_number" do
    let(:completed_form) { create :form, :live }

    context "with an existing page" do
      let(:page) { completed_form.pages.first }

      it "returns the page position" do
        expect(completed_form.page_number(page)).to eq(page.position)
      end

      context "when the page's attributes have changed but it has the same ID" do
        before do
          page.update(question_text: "different question text")
        end

        it "returns the page position" do
          expect(completed_form.page_number(page)).to eq(page.position)
        end
      end
    end

    context "with an new page" do
      let(:page) { create :page }

      it "returns the position for a new page" do
        expect(completed_form.page_number(page)).to eq(completed_form.pages.count + 1)
      end
    end

    context "with an unspecified page" do
      it "returns the position for a new page" do
        expect(completed_form.page_number(nil)).to eq(completed_form.pages.count + 1)
      end
    end

    context "with a page which has a null id" do
      let(:page) { build :page, id: nil }

      it "returns the position for a new page" do
        expect(completed_form.page_number(nil)).to eq(completed_form.pages.count + 1)
      end
    end
  end

  describe "#email_confirmation_status" do
    let(:form) { create :form, :new_form }

    it "returns :not_started" do
      expect(form.email_confirmation_status).to eq(:not_started)
    end

    it "with submission_email set and no FormSubmissionEmail, returns :email_set_without_confirmation" do
      form.submission_email = "test@example.gov.uk"
      expect(form.email_confirmation_status).to eq(:email_set_without_confirmation)
    end

    it "with FormSubmissionEmail code returns :sent" do
      create :form_submission_email, form_id: form.id, temporary_submission_email: "test@example.gov.uk", confirmation_code: "123456"
      expect(form.email_confirmation_status).to eq(:sent)
    end

    it "with FormSubmissionEmail with no code returns :confirmed" do
      create :form_submission_email, form_id: form.id, temporary_submission_email: "test@example.gov.uk", confirmation_code: ""
      expect(form.email_confirmation_status).to eq(:confirmed)
    end

    it "with FormSubmissionEmail with code and email matches forms returns :confirmed" do
      form.submission_email = "test@example.gov.uk"
      create :form_submission_email, form_id: form.id, temporary_submission_email: "test@example.gov.uk", confirmation_code: "123456"
      expect(form.email_confirmation_status).to eq(:confirmed)
    end
  end

  describe "#qualifying_route_pages" do
    let(:form) { create :form }
    let!(:non_selection_page) { create(:page, form:, position: 1) }
    let!(:selection_page_without_routes) { create(:page, :with_selection_settings, form:, position: 2) }
    let!(:selection_page_with_route) { create(:page, :with_selection_settings, form:, position: 3) }
    let!(:selection_page_with_branching) { create(:page, :with_selection_settings, form:, position: 4) }
    let!(:secondary_skip_page) { create(:page, :with_selection_settings, form:, position: 5) }
    let!(:branch_route_go_to_page) { create(:page, :with_selection_settings, form:, position: 6) }
    let!(:last_page) { create(:page, :with_selection_settings, form:, position: 7) }

    before do
      create(:condition, routing_page_id: selection_page_with_route.id, check_page_id: selection_page_with_route.id, answer_value: "Option 1", goto_page_id: secondary_skip_page.id)

      create(:condition, routing_page_id: selection_page_with_branching.id, check_page_id: selection_page_with_branching.id, answer_value: "Option 1", goto_page_id: branch_route_go_to_page.id)
      create(:condition, routing_page_id: secondary_skip_page.id, check_page_id: selection_page_with_branching.id, goto_page_id: last_page.id)

      form.reload
      form.pages.each(&:reload)

      allow(form).to receive(:group).and_return(build(:group))
    end

    it "does not include a question which does not have answer type selection" do
      expect(form.qualifying_route_pages).not_to include non_selection_page
    end

    it "includes a question which has answer type selection and no existing conditions" do
      expect(form.qualifying_route_pages).to include selection_page_without_routes
    end

    it "includes a question which has answer type selection, an existing condition, and no secondary skip condition" do
      expect(form.qualifying_route_pages).to include selection_page_with_route
    end

    it "does not include a question which already has a condition and a secondary skip condition" do
      expect(form.qualifying_route_pages).not_to include selection_page_with_branching
    end

    it "does not include a question which is the routing page for a secondary skip condition" do
      expect(form.qualifying_route_pages).not_to include secondary_skip_page
    end

    it "includes a page that is the go to page for a condition that is also qualifying page" do
      expect(form.qualifying_route_pages).to include branch_route_go_to_page
    end

    it "does not include the final page of the form, which is otherwise a qualifying page" do
      expect(form.qualifying_route_pages).not_to include last_page
    end
  end

  describe "#has_no_remaining_routes_available?" do
    context "when the form has routes" do
      let(:form) { create :form }
      let(:pages) do
        [
          create(:page, :with_selection_settings, form:, position: 1),
          create(:page, :with_selection_settings, form:, position: 2),
          create(:page, :with_selection_settings, form:, position: 3),
        ]
      end

      before do
        create :condition, routing_page_id: pages.first.id, check_page_id: pages.first.id, answer_value: "Option 1", skip_to_end: true
        form.pages.each(&:reload)
      end

      context "when there is a page that a route can be added to" do
        it "returns false" do
          expect(form.has_no_remaining_routes_available?).to be(false)
        end
      end

      context "when there are no pages that a route can be added to" do
        before do
          create :condition, routing_page_id: pages.second.id, check_page_id: pages.first.id, skip_to_end: true
          form.pages.each(&:reload)
        end

        it "returns true" do
          expect(form.reload.has_no_remaining_routes_available?).to be(true)
        end
      end
    end

    context "when the form does not have routes" do
      let(:form) { create :form }
      let(:pages) { create_list :page, 3, :with_selection_settings, form: }

      it "returns false" do
        expect(form.has_no_remaining_routes_available?).to be(false)
      end
    end
  end

  describe "#group" do
    let(:form) { create :form }

    it "returns nil if form is not in a group" do
      expect(form.group).to be_nil
    end

    it "returns the group if form is in a group" do
      group = create :group
      GroupForm.create!(form_id: form.id, group_id: group.id)
      expect(form.group).to eq group
    end
  end

  describe "#file_upload_question_count" do
    let(:form) { create :form }

    before do
      create_list :page, 3, form:, answer_type: :file
      Page::ANSWER_TYPES.each do |answer_type|
        create(:page, form:, answer_type:)
      end
    end

    it "returns the number of file upload questions" do
      expect(form.reload.file_upload_question_count).to eq(4)
    end
  end

  describe "#as_form_document" do
    let(:form) do
      create(:form, :ready_for_live, delivery_configurations: [
        create(:delivery_configuration),
        create(:delivery_configuration, :daily_email),
      ])
    end

    it "includes all attributes for the form" do
      form_attributes = described_class.attribute_names - %w[id state external_id pages question_section_completed declaration_section_completed share_preview_completed welsh_completed]
      expect(form.as_form_document).to match a_hash_including(*form_attributes)
    end

    it "includes the form ID" do
      form_document = form.as_form_document
      expect(form_document).to include "form_id" => form.id.to_s
      expect(form_document).not_to include "id"
    end

    it "includes start page" do
      expect(form.as_form_document).to match a_hash_including("start_page" => form.pages.first.external_id)
    end

    it "includes steps" do
      expect(form.as_form_document["steps"].count).to eq(form.pages.count)
      expect(form.as_form_document["steps"].first).to match a_hash_including(
        "type" => "question",
        "next_step_id" => form.pages.second.external_id,
      )
      expect(form.as_form_document["steps"].last).to match a_hash_including(
        "type" => "question",
        "next_step_id" => nil,
      )
    end

    it "includes the delivery configurations" do
      expect(form.as_form_document["delivery_configurations"]).to match a_hash_including(
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
      )
    end

    it "does not include a live_at date" do
      expect(form.as_form_document).not_to have_key("live_at")
    end

    context "when a live_at date is provided" do
      it "includes the live_at date" do
        live_at = Time.zone.local(2023, 10, 16, 13, 24)
        expect(form.as_form_document(live_at:)["live_at"]).to eq("2023-10-16 13:24:00.000000")
      end
    end

    it "includes default language if not provided" do
      expect(form.as_form_document["language"]).to eq("en")
    end

    it "includes the language if provided" do
      expect(form.as_form_document(language: :cy)["language"]).to eq("cy")
    end

    it "does not include language if blank or nil" do
      expect(form.as_form_document(language: "")["language"]).to be_nil
      expect(form.as_form_document(language: nil)["language"]).to be_nil
    end
  end

  describe "#has_welsh_translation?" do
    let(:form) { create :form, :ready_for_live }
    let(:group) { create :group }

    before do
      GroupForm.create!(group:, form:)
    end

    context "when the available_languages array does not include Welsh" do
      let(:form) { create :form, :ready_for_live, available_languages: %w[en] }

      it "returns false" do
        expect(form.has_welsh_translation?).to be false
      end
    end

    context "when the available_languages field does includes Welsh" do
      let(:form) { create :form, :ready_for_live, available_languages: %w[en cy] }

      it "returns true" do
        expect(form.has_welsh_translation?).to be true
      end
    end
  end

  describe "#normalise_welsh!" do
    let!(:form) { create(:form, available_languages: languages, pages: [page]) }
    let!(:page) { create(:page) }
    let(:welsh_attributes) do
      {
        declaration_markdown: "cy declaration",
        payment_url: "https://cy.example.com",
        support_email: "cy@example.com",
        support_phone: "cy phone",
        support_url: "https://cy.support.com",
        support_url_text: "cy support text",
        what_happens_next_markdown: "cy what happens next",
      }
    end

    describe "#draft_created?" do
      subject(:draft_created?) { form.draft_created?(initial_state) }

      context "when a draft has been created for a live form" do
        let(:form) { create(:form, :live_with_draft) }
        let(:initial_state) { "live" }

        it { is_expected.to be true }
      end

      context "when a draft has been created for an archived form" do
        let(:form) { create(:form, :archived_with_draft) }
        let(:initial_state) { "archived" }

        it { is_expected.to be true }
      end

      context "when the state has not changed" do
        let(:form) { create(:form, :live_with_draft) }
        let(:initial_state) { "live_with_draft" }

        it { is_expected.to be false }
      end

      context "when the state has been updated to live" do
        let(:form) { create(:form, :live) }
        let(:initial_state) { "live_with_draft" }

        it { is_expected.to be false }
      end

      context "when the state has been updated from live with draft to archived with draft" do
        let(:form) { create(:form, :archived_with_draft) }
        let(:initial_state) { "live_with_draft" }

        it { is_expected.to be false }
      end
    end

    context "when Welsh is not an available language" do
      let(:languages) { %w[en] }

      it "does not clear any Welsh translations" do
        Mobility.with_locale(:cy) do
          welsh_attributes.each do |attr, value|
            form.send("#{attr}=", value)
          end
        end

        form.normalise_welsh!

        Mobility.with_locale(:cy) do
          welsh_attributes.each do |attr, value|
            expect(form.send(attr)).to eq(value)
          end
        end
      end

      it "does not call normalise_welsh! on its pages" do
        allow(page).to receive(:normalise_welsh!)
        form.normalise_welsh!
        expect(page).not_to have_received(:normalise_welsh!)
      end
    end

    context "when Welsh is an available language" do
      let(:languages) { %w[en cy] }

      it "calls normalise_welsh! on each of its pages" do
        allow(page).to receive(:normalise_welsh!)
        form.normalise_welsh!
        expect(page).to have_received(:normalise_welsh!)
      end

      context "when the English attributes are present" do
        before do
          form.declaration_markdown = "en declaration"
          form.payment_url = "https://en.example.com"

          form.declaration_markdown_cy = "cy declaration"
          form.payment_url_cy = "https://cy.example.com"

          form.save!
        end

        it "does not clear the Welsh translations" do
          form.normalise_welsh!
          form.reload
          expect(form.declaration_markdown_cy).to eq("cy declaration")
          expect(form.payment_url_cy).to eq("https://cy.example.com")
        end
      end

      context "when the English attributes are blank" do
        before do
          Mobility.with_locale(:en) do
            welsh_attributes.each_key do |attr|
              form.send("#{attr}=", "")
            end
          end

          Mobility.with_locale(:cy) do
            welsh_attributes.each do |attr, value|
              form.send("#{attr}=", value)
            end
          end
          form.save!
        end

        it "clears the corresponding Welsh translations" do
          form.normalise_welsh!

          Mobility.with_locale(:cy) do
            welsh_attributes.each_key do |attr|
              expect(form.send(attr)).to be_nil
            end
          end
        end
      end
    end
  end

  describe "#next_page_after" do
    let(:pages) { [] }
    let(:form) { build :form, pages: }

    it "returns nil if there is no next page" do
      expect(form.next_page_after(form.pages.first)).to be_nil
    end

    context "when there is a next page" do
      let(:pages) { build_list :page, 5 }

      it "returns the next page" do
        expect(form.next_page_after(form.pages.second)).to eq(form.pages.third)
      end
    end
  end

  describe "#can_make_language_live" do
    let(:form) { create :form }

    before do
      form.set_task_status_service(TaskStatusService.new(form:, current_user:))
    end

    context "when the language being checked is English" do
      let(:language) { "en" }

      context "when the form is draft" do
        context "when the form does not have all mandatory tasks completed" do
          let(:form) { create :form }

          it "returns false" do
            expect(form.can_make_language_live?(language:)).to be false
          end
        end

        context "when the form has all mandatory tasks completed" do
          let(:form) { create :form, :ready_for_live }

          context "when the form does not have a live English form document" do
            context "when the form does not have a live Welsh form document" do
              context "when the Welsh task has not been started" do
                it "returns true" do
                  expect(form.can_make_language_live?(language:)).to be true
                end
              end

              context "when the Welsh task is still in progress" do
                let(:form) { create :form, :ready_for_live, :with_welsh_translation, welsh_completed: false }

                it "returns true" do
                  expect(form.can_make_language_live?(language:)).to be true
                end
              end

              context "when the Welsh task is complete" do
                let(:form) { create :form, :ready_for_live, :with_welsh_translation }

                it "returns true" do
                  expect(form.can_make_language_live?(language:)).to be true
                end
              end
            end

            context "when the form already has a live Welsh form document" do
              before do
                create :form_document, :live, form:, language: "cy", content: form.as_form_document
              end

              it "returns false" do
                expect(form.can_make_language_live?(language:)).to be false
              end
            end
          end

          context "when the form already has a live English form document" do
            before do
              create :form_document, :live, form:, language: "en", content: form.as_form_document
            end

            it "returns true" do
              expect(form.can_make_language_live?(language:)).to be true
            end
          end
        end
      end

      context "when the form is live" do
        context "when the form has all mandatory tasks completed" do
          let(:form) { create :form, state: "live" }

          context "when the form does not have a live English form document" do
            context "when the form does not have a live Welsh form document" do
              it "returns false" do
                expect(form.can_make_language_live?(language:)).to be false
              end
            end

            context "when the form already has a live Welsh form document" do
              before do
                create :form_document, :live, form:, language: "cy", content: form.as_form_document
              end

              it "returns false" do
                expect(form.can_make_language_live?(language:)).to be false
              end
            end
          end

          context "when the form already has a live English form document" do
            before do
              create :form_document, :live, form:, language: "en", content: form.as_form_document
            end

            it "returns false" do
              expect(form.can_make_language_live?(language:)).to be false
            end
          end
        end
      end
    end

    context "when the language being checked is Welsh" do
      let(:language) { "cy" }

      context "when the form is draft" do
        context "when the form does not have all mandatory tasks completed" do
          let(:form) { create :form }

          it "returns false" do
            expect(form.can_make_language_live?(language:)).to be false
          end
        end

        context "when the form has all mandatory tasks completed" do
          let(:form) { create :form, :ready_for_live }

          context "when the form does not have a live English form document" do
            context "when the form does not have a live Welsh form document" do
              it "returns false" do
                expect(form.can_make_language_live?(language:)).to be false
              end
            end

            context "when the form already has a live Welsh form document" do
              before do
                create :form_document, :live, form:, language: "cy", content: form.as_form_document
              end

              it "returns false" do
                expect(form.can_make_language_live?(language:)).to be false
              end
            end
          end

          context "when the form already has a live English form document" do
            before do
              create :form_document, :live, form:, language: "en", content: form.as_form_document
            end

            it "returns false" do
              expect(form.can_make_language_live?(language:)).to be false
            end
          end
        end
      end

      context "when the form is live" do
        let(:form) { create :form, :ready_for_live, state: "live" }

        context "when the form does not have a live English form document" do
          context "when the form does not have a live Welsh form document" do
            it "returns false" do
              expect(form.can_make_language_live?(language:)).to be false
            end
          end

          context "when the form already has a live Welsh form document" do
            before do
              create :form_document, :live, form:, language: "cy", content: form.as_form_document
            end

            it "returns false" do
              expect(form.can_make_language_live?(language:)).to be false
            end
          end
        end

        context "when the form already has a live English form document" do
          before do
            create :form_document, :live, form:, language: "en", content: form.as_form_document
          end

          context "when the form does not have a live Welsh form document" do
            context "when the Welsh task has not been started" do
              it "returns false" do
                expect(form.can_make_language_live?(language:)).to be false
              end
            end

            context "when the Welsh task is still in progress" do
              let(:form) { create :form, :ready_for_live, :with_welsh_translation, state: "live", welsh_completed: false }

              it "returns false" do
                expect(form.can_make_language_live?(language:)).to be false
              end
            end

            context "when the Welsh task is complete" do
              let(:form) { create :form, :ready_for_live, :with_welsh_translation, state: "live" }

              it "returns true" do
                expect(form.can_make_language_live?(language:)).to be true
              end

              context "when there are changes which have not yet been made live on the English version" do
                before do
                  form.name = "A new form name"
                  form.save_draft!

                  form.share_preview_completed = true
                  form.save_draft!
                end

                it "returns false" do
                  expect(form.can_make_language_live?(language:)).to be false
                end
              end
            end

            context "when the Welsh task has been completed since the English form was made live" do
              let(:form) { create :form, :ready_for_live, :with_welsh_translation, state: "live", welsh_completed: false }

              before do
                form.welsh_completed = true
                form.save_draft!

                form.share_preview_completed = true
                form.save_draft!
              end

              it "returns true" do
                expect(form.can_make_language_live?(language:)).to be true
              end
            end
          end

          context "when the form already has a live Welsh form document" do
            before do
              create :form_document, :live, form:, language: "cy", content: form.as_form_document
            end

            it "returns false" do
              expect(form.can_make_language_live?(language:)).to be false
            end
          end
        end
      end
    end
  end
end
