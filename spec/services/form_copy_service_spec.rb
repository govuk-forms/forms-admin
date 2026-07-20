require "rails_helper"

RSpec.describe FormCopyService do
  let(:group) { create(:group) }
  let(:source_form) { create(:form, :live_with_draft, :with_s3_configuration) }
  let(:source_form_document) { FormDocument.find_by(form_id: source_form.id) }
  let(:logged_in_user) { create(:user) }
  let(:tag) { "live" }
  let(:copied_form) { described_class.new(source_form, logged_in_user).copy(tag:) }

  before do
    GroupForm.create!(form: source_form, group: group)
  end

  describe "#copy" do
    it "creates a new form" do
      expect(copied_form).to be_a(Form)
      expect(copied_form).to be_persisted
      expect(copied_form.id).not_to eq(source_form.id)
    end

    it "sets the creator as the user who copied the form (the logged in user)" do
      source_form.creator_id = create(:user).id

      expect(copied_form.creator_id).not_to eq(source_form.creator_id)
      expect(copied_form.creator_id).to eq(logged_in_user.id)
    end

    it "has a reference to the original form" do
      expect(copied_form.copied_from_id).to eq(source_form.id)
    end

    it "sets copied_from_id in the FormDocument content" do
      form_document = copied_form.draft_form_document
      expect(form_document.content["copied_from_id"]).to eq(source_form.id)
    end

    it "copies and updates the name of the copy" do
      expect(copied_form.name).to eq("Copy of #{source_form.name}")
    end

    it "copies the language from the source form document" do
      expect(copied_form.draft_form_document.language).to eq("en")
    end

    it "associates the draft form document with the new form" do
      expect(copied_form.draft_form_document.form).to eq(copied_form)
    end

    it "has different created_at and updated_at timestamps from the source form" do
      expect(copied_form.created_at).not_to be_nil
      expect(copied_form.created_at).not_to eq(source_form.created_at)

      expect(copied_form.updated_at).not_to be_nil
      expect(copied_form.updated_at).not_to eq(source_form.updated_at)
    end

    it "does not copy attributes that we exclude from copying" do
      expect(copied_form.first_made_live_at).to be_nil
      expect(copied_form.submission_email).to be_nil
      expect(copied_form.s3_bucket_aws_account_id).to be_nil
      expect(copied_form.s3_bucket_name).to be_nil
      expect(copied_form.s3_bucket_region).to be_nil
    end

    context "when source form has completed tasks" do
      before do
        source_form.update!(
          question_section_completed: true,
          declaration_section_completed: true,
          share_preview_completed: true,
          welsh_completed: true,
        )
      end

      it "resets all task completion flags to unstarted" do
        expect(source_form.question_section_completed).to be true
        expect(source_form.declaration_section_completed).to be true
        expect(source_form.share_preview_completed).to be true
        expect(source_form.welsh_completed).to be true

        expect(copied_form.question_section_completed).to be false
        expect(copied_form.declaration_section_completed).to be false
        expect(copied_form.share_preview_completed).to be false
        expect(copied_form.welsh_completed).to be false
      end
    end

    context "when source form has pages" do
      let(:source_form) { create(:form, :live_with_draft, :with_pages, pages_count: 3) }

      it "copies all pages to the new form" do
        expect(copied_form.pages.count).to be > 0
        expect(copied_form.pages.count).to eq(source_form.pages.count)
      end

      it "creates new page records with different IDs" do
        source_page_ids = source_form.pages.pluck(:id)
        copied_page_ids = copied_form.pages.pluck(:id)

        expect(copied_page_ids).not_to be_blank
        expect(copied_page_ids).not_to include(*source_page_ids)
      end

      it "copies page attributes" do
        source_page = source_form.pages.first
        copied_page = copied_form.pages.first

        expect(copied_page.question_text).to eq(source_page.question_text)
        expect(copied_page.answer_type).to eq(source_page.answer_type)
        expect(copied_page.is_optional).to eq(source_page.is_optional)
      end

      it "maintains page positions" do
        source_positions = source_form.pages.pluck(:position)
        copied_positions = copied_form.pages.pluck(:position)

        expect(copied_positions).to eq(source_positions)
      end

      it "has different created_at timestamps for pages" do
        source_page = source_form.pages.first
        copied_page = copied_form.pages.first

        expect(copied_page.created_at).not_to be_nil
        expect(copied_page.created_at).not_to eq(source_page.created_at)
      end

      it "has the same number of steps as the source form has pages in the draft FormDocument" do
        expect(copied_form.draft_form_document.content["steps"].count).to eq(source_form.pages.count)
      end
    end

    context "when source form has pages with routing conditions" do
      let(:source_form) { create(:form, :live_with_draft, :ready_for_routing, pages_count: 3) }

      before do
        create(:condition,
               form: source_form,
               routing_page: source_form.pages.first,
               check_page: source_form.pages.first,
               goto_page: source_form.pages.last,
               answer_value: "Yes")
        source_form.reload

        # Update the live form document to include the pages and conditions
        source_form.live_form_document.update!(content: source_form.as_form_document)
      end

      it "copies routing conditions to the new form" do
        source_conditions_count = source_form.pages.first.routing_conditions.count
        copied_conditions_count = copied_form.pages.first.routing_conditions.count

        expect(copied_conditions_count).to be > 0
        expect(copied_conditions_count).to eq(source_conditions_count)
      end

      it "creates new condition records with different IDs" do
        source_condition_ids = source_form.conditions.pluck(:id)
        copied_condition_ids = copied_form.conditions.pluck(:id)

        expect(copied_condition_ids).not_to be_blank
        expect(copied_condition_ids).not_to include(*source_condition_ids)
      end

      it "copies condition attributes" do
        source_condition = source_form.pages.first.routing_conditions.first
        copied_condition = copied_form.pages.first.routing_conditions.first

        expect(copied_condition.answer_value).to eq(source_condition.answer_value)
        expect(copied_condition.skip_to_end).to eq(source_condition.skip_to_end)
      end

      it "maintains correct page associations for conditions" do
        copied_condition = copied_form.pages.first.routing_conditions.first

        expect(copied_condition.routing_page).to eq(copied_form.pages.first)
        expect(copied_condition.check_page).to eq(copied_form.pages.first)
        expect(copied_condition.goto_page).to eq(copied_form.pages.last)
      end
    end

    context "when source form has pages with exit page conditions" do
      let(:source_form) { create(:form, :live_with_draft, :ready_for_routing, pages_count: 2) }
      let!(:exit_condition) do
        create(:condition, :with_exit_page,
               form: source_form,
               routing_page: source_form.pages.first,
               check_page: source_form.pages.first,
               answer_value: "No")
      end

      before do
        source_form.reload

        # Update the live form document to include the pages and conditions
        source_form.live_form_document.update!(content: source_form.as_form_document)
      end

      it "copies exit page conditions" do
        copied_condition = copied_form.pages.first.routing_conditions.first

        expect(copied_condition.exit_page_heading).to eq(exit_condition.exit_page_heading)
        expect(copied_condition.exit_page_markdown).to eq(exit_condition.exit_page_markdown)
      end

      it "does not associate with a goto_page for exit conditions" do
        copied_condition = copied_form.pages.first.routing_conditions.first

        expect(copied_condition.goto_page).to be_nil
      end
    end

    context "when copying from a draft form document" do
      let(:source_form_document) { create(:form_document, :draft, form: source_form) }

      it "creates a draft form document for the new form" do
        expect(copied_form.draft_form_document.tag).to eq("draft")
      end
    end

    context "when copying from an live form document" do
      let(:source_form_document) { create(:form_document, :live, form: source_form) }

      it "creates a draft form document for the new form" do
        expect(copied_form.state).to eq("draft")
      end
    end

    context "when copying from an archived form document" do
      let(:source_form_document) { create(:form_document, :archived, form: source_form) }

      it "creates a draft form document for the new form" do
        expect(copied_form.state).to eq("draft")
      end
    end

    context "when source form is in a group" do
      let(:group) { create(:group) }

      context "when copying a live form" do
        let(:source_form) { create(:form, :live_with_draft) }

        it "places the copied form in the same group as the original form" do
          expect(copied_form.group).to eq(source_form.group)
          expect(copied_form.group).to eq(group)
        end
      end

      context "when copying a draft form with no pages" do
        let(:source_form) { create(:form) }
        let(:tag) { "draft" }

        it "places the copied form in the same group as the original form" do
          expect(copied_form.group).to eq(source_form.group)
          expect(copied_form.group).to eq(group)
        end
      end
    end

    context "when source form has Welsh language version with translated content" do
      let(:source_form) do
        form = create(:form, :live, :with_pages, pages_count: 2, available_languages: %w[en cy], support_phone: "01234 567890", support_url: "https://example.gov.uk/support", support_url_text: "Our English support site", declaration_markdown: "English declaration", payment_url: "https://www.pay.gov.uk")
        # Add an exit page condition to the first page
        form.pages.first.answer_type = "selection"
        form.pages.first.hint_text = "English hint text"
        form.pages.first.page_heading = "English page heading"
        form.pages.first.guidance_markdown = "English guidance markdown"
        form.pages.first.answer_settings = DataStruct.new(only_one_option: true,
                                                          selection_options: [{ name: "Option 1", value: "Option 1" }, { name: "Option 2", value: "Option 2" }])
        form.pages.first.routing_conditions << Condition.new(routing_page_id:
                                                             form.pages.first.id,
                                                             check_page_id:
                                                             form.pages.first.id,
                                                             answer_value:
                                                             "Option 1",
                                                             goto_page_id: nil,
                                                             skip_to_end: true,
                                                             exit_page_heading:
                                                             "Exit page heading English",
                                                             exit_page_markdown: "Exit page markdown English")
        form.pages.last.hint_text = "English last page hint text"
        # Set Welsh-specific translations for form
        form.name_cy = "Ffurflen Gymraeg"
        form.privacy_policy_url_cy = "https://example.com/preifatrwydd"
        form.support_email_cy = "cymorth@example.com"
        form.support_phone_cy = "0800 111 222"
        form.support_url_cy = "https://example.com/cymorth"
        form.support_url_text_cy = "Cael cymorth"
        form.declaration_markdown_cy = "Rwy'n datgan bod hyn yn wir"
        form.what_happens_next_markdown_cy = "Byddwn yn cysylltu â chi"
        form.payment_url_cy = "https://example.com/talu"
        form.save!
        # Set Welsh translations for pages - must save each page individually
        form.pages.first.update!(question_text_cy: "Cwestiwn Cymraeg 1", hint_text_cy: "Awgrym Cymraeg 1", page_heading_cy: "Pennwr Tudalen Cymraeg 1")
        form.pages.last.update!(question_text_cy: "Cwestiwn Cymraeg 2", hint_text_cy: "Awgrym Cymraeg 2")

        # Set the Welsh exit page text
        exit_page = form.pages.first.routing_conditions.first
        exit_page.exit_page_heading_cy = "Welsh exit page heading"
        exit_page.exit_page_markdown_cy = "Welsh exit page markdown"
        exit_page.save!

        # Synchronize live FormDocuments for both languages
        FormDocumentSyncService.new(form).synchronize_live_form
        form.reload
        form
      end

      it "copies the Welsh-translated content from the source form" do
        source_welsh = source_form.form_documents.find_by(language: "cy", tag: "live")
        expect(source_welsh).to be_present
        expect(source_welsh.content["name"]).to eq("Ffurflen Gymraeg")

        # Copied form should have Welsh FormDocument with translated content
        copied_welsh = copied_form.form_documents.find_by(language: "cy", tag: "draft")
        expect(copied_welsh).to be_present
        expect(copied_welsh.content["name"]).to eq("Copy of Ffurflen Gymraeg")
        expect(copied_welsh.content["privacy_policy_url"]).to eq("https://example.com/preifatrwydd")
        expect(copied_welsh.content["support_email"]).to eq("cymorth@example.com")
        expect(copied_welsh.content["support_phone"]).to eq("0800 111 222")
        expect(copied_welsh.content["support_url"]).to eq("https://example.com/cymorth")
        expect(copied_welsh.content["support_url_text"]).to eq("Cael cymorth")
        expect(copied_welsh.content["declaration_markdown"]).to eq("Rwy'n datgan bod hyn yn wir")
        expect(copied_welsh.content["what_happens_next_markdown"]).to eq("Byddwn yn cysylltu â chi")
        expect(copied_welsh.content["payment_url"]).to eq("https://example.com/talu")
      end

      it "persists Welsh translations on the copied Form model" do
        # Ensure model-level Mobility translations are set correctly
        expect(copied_form.name_cy).to eq("Copy of Ffurflen Gymraeg")
        expect(copied_form.privacy_policy_url_cy).to eq("https://example.com/preifatrwydd")
        expect(copied_form.support_email_cy).to eq("cymorth@example.com")
        expect(copied_form.support_phone_cy).to eq("0800 111 222")
        expect(copied_form.support_url_cy).to eq("https://example.com/cymorth")
        expect(copied_form.support_url_text_cy).to eq("Cael cymorth")
        expect(copied_form.declaration_markdown_cy).to eq("Rwy'n datgan bod hyn yn wir")
        expect(copied_form.what_happens_next_markdown_cy).to eq("Byddwn yn cysylltu â chi")
        expect(copied_form.payment_url_cy).to eq("https://example.com/talu")

        # Check that values are accessible in Welsh locale context
        Mobility.with_locale(:cy) do
          expect(copied_form.name).to eq("Copy of Ffurflen Gymraeg")
          expect(copied_form.privacy_policy_url).to eq("https://example.com/preifatrwydd")
          expect(copied_form.support_email).to eq("cymorth@example.com")
        end
      end

      it "persists Welsh translations on copied pages" do
        expect(copied_form.pages.count).to eq(2)

        # Reload to get the latest state from the database
        copied_form.reload
        first_page = copied_form.pages.first
        expect(first_page.question_text_cy).to eq("Cwestiwn Cymraeg 1")
        expect(first_page.hint_text_cy).to eq("Awgrym Cymraeg 1")
        expect(first_page.page_heading_cy).to eq("Pennwr Tudalen Cymraeg 1")

        last_page = copied_form.pages.last
        expect(last_page.question_text_cy).to eq("Cwestiwn Cymraeg 2")
        expect(last_page.hint_text_cy).to eq("Awgrym Cymraeg 2")

        # Check that page values are accessible in Welsh locale context
        Mobility.with_locale(:cy) do
          expect(first_page.question_text).to eq("Cwestiwn Cymraeg 1")
          expect(first_page.hint_text).to eq("Awgrym Cymraeg 1")
        end
      end

      it "persists Welsh translations on copied exit page conditions" do
        copied_condition = copied_form.pages.first.routing_conditions.first

        expect(copied_condition.exit_page_heading_cy).to eq("Welsh exit page heading")
        expect(copied_condition.exit_page_markdown_cy).to eq("Welsh exit page markdown")
      end
    end

    context "when Welsh copy fails" do
      let(:source_form) do
        form = create(:form, :live, available_languages: %w[en cy])
        form.name_cy = "Ffurflen Gymraeg"
        form.save!
        FormDocumentSyncService.new(form).synchronize_live_form
        form
      end

      it "rolls back the entire copy if Welsh translation copying fails" do
        # Stub the Welsh copying to raise an AR::RecordInvalid to simulate a failure mid-transaction
        service = described_class.new(source_form, logged_in_user)
        allow(service).to receive(:copy_welsh_translations)
          .and_raise(ActiveRecord::RecordInvalid.new(Form.new))

        expect {
          service.copy(tag: "live")
        }.to raise_error(ActiveRecord::RecordInvalid)

        # Ensure no copied form was persisted
        expect(Form.where(copied_from_id: source_form.id)).to be_empty
      end
    end
  end
end
