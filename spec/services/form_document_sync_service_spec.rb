require "rails_helper"

RSpec.describe FormDocumentSyncService do
  let(:service) { described_class.new(form) }
  let(:form) { create(:form) }

  describe "#synchronize_live_form" do
    let!(:form) { create(:form, state: "live") }
    let(:expected_live_at) { form.reload.updated_at.as_json }

    context "when there is no existing form document" do
      it "creates a live form document" do
        expect {
          service.synchronize_live_form
        }.to change(FormDocument, :count).by(1)

        expect(form.latest_form_document).to have_attributes(form:, tag: "live", content: form.as_form_document(live_at: expected_live_at), version: 1)
      end

      it "sets the latest_form_document_id on the form" do
        service.synchronize_live_form
        expect(form.reload.latest_form_document_id).to eq(FormDocument.last.id)
      end
    end

    context "when there is an existing live form document" do
      let!(:form_document) { create :form_document, :live, form:, content: form.as_form_document, version: 1 }

      before do
        form.latest_form_document = form_document
        form.save!
      end

      it "increments the latest form document with a new version" do
        expect {
          service.synchronize_live_form
        }.to change { form.reload.latest_form_document.version }.from(1).to(2)
      end

      it "creates a new live form document with the new content" do
        new_name = "new name"
        form.name = new_name
        form.save!
        expect {
          service.synchronize_live_form
        }.to change { form.reload.latest_form_document.content["name"] }.to(new_name)
      end

      it "sets the live_at date in the new form document" do
        service.synchronize_live_form
        expect(form.reload.latest_form_document.content).to include("live_at" => form.reload.updated_at.as_json)
      end

      it "does not change the version of the existing form document" do
        expect {
          service.synchronize_live_form
        }.not_to(change { form_document.reload.version })
      end
    end

    context "when there is an existing archived form document" do
      before do
        create :form_document, :archived, form:
      end

      it "destroys the archived form document" do
        expect {
          service.synchronize_live_form
        }.to(change { FormDocument.exists?(form:, tag: "archived") }.from(true).to(false))
      end

      it "creates the live form document" do
        expect {
          service.synchronize_live_form
        }.to(change { FormDocument.exists?(form:, tag: "live") }.from(false).to(true))
      end

      context "and deleting the archived FormDocument fails" do
        before do
          allow(service).to receive(:delete_form_documents_by_tag).with(FormDocumentSyncService::ARCHIVED_TAG)
            .and_raise(ActiveRecord::StatementInvalid)
        end

        it "does not create the live FormDocument" do
          expect {
            service.synchronize_live_form
          }.to raise_error(ActiveRecord::StatementInvalid).and not_change(FormDocument, :count)
        end
      end
    end

    context "when the form has Welsh translations" do
      let(:form) { create(:form, :live, :with_welsh_translation) }

      it "creates live form documents with an incremented version number" do
        expect {
          service.synchronize_live_form
        }.to change(FormDocument, :count).by(2)
        .and change { form.reload.latest_form_document.version }.by(1)
        .and change { form.reload.latest_welsh_form_document.version }.by(1)
      end

      it "sets the latest_form_document_id on the form to the English form document" do
        service.synchronize_live_form
        expect(form.reload.latest_form_document_id).to eq(FormDocument.order(version: :desc).find_by(form:, tag: "live", language: "en").id)
      end

      context "and the Welsh form fails to save" do
        before do
          allow(service).to receive(:update_or_create_form_document).and_call_original
          # saving welsh form fails
          allow(service).to receive(:update_or_create_form_document)
            .with("live", anything, "cy", anything)
            .and_raise(ActiveRecord::RecordInvalid.new(form), "simulated FormDocument saving error")
        end

        it "does not create any FormDocuments" do
          expect {
            service.synchronize_live_form
          }.to raise_error(ActiveRecord::RecordInvalid).and not_change(FormDocument, :count)
        end
      end
    end
  end

  describe "#synchronize_archived_form" do
    context "when there is no existing live form document" do
      it "raises an ActiveRecord::RecordNotFound error" do
        expect {
          service.synchronize_archived_form
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when there is an existing live form document" do
      let!(:live_form_document) { create :form_document, :live, form:, content: "content" }

      it "updates the live form document to be archived" do
        expect {
          service.synchronize_archived_form
        }.to(change { live_form_document.reload.tag }.from("live").to("archived"))
      end
    end
  end

  describe "#synchronize_archived_welsh_form" do
    let(:form) { create(:form, available_languages: %w[en cy], state: "live", welsh_completed: true) }

    context "when there is no existing live form document" do
      it "raises an ActiveRecord::RecordNotFound error" do
        expect {
          service.synchronize_archived_welsh_form
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when there is an existing live Welsh form document" do
      let!(:live_form_document_cy) { create :form_document, :live, form:, language: "cy", content: { "available_languages" => %w[en cy] } }
      let!(:live_form_document_en) { create :form_document, :live, form:, language: "en", content: { "available_languages" => %w[en cy] } }

      before do
        form.latest_form_document = live_form_document_en
        form.save!
      end

      it "updates the live Welsh form document to be archived" do
        expect {
          service.synchronize_archived_form
        }.to(change { live_form_document_cy.reload.tag }.from("live").to("archived"))
      end

      it "changes the available languages in the form to only include English" do
        expect {
          service.synchronize_archived_welsh_form
        }.to(change(form, :available_languages).from(%w[en cy]).to(%w[en]))
      end

      it "changes the Welsh completed status in the form to false" do
        expect {
          service.synchronize_archived_welsh_form
        }.to(change(form, :welsh_completed).from(true).to(false))
      end

      it "changes the available languages in the draft English form document to only include English" do
        expect {
          service.synchronize_archived_welsh_form
        }.to(change { form.draft_form_document.reload.content["available_languages"] }.from(%w[en cy]).to(%w[en]))
      end

      it "creates a new live English form document with an updated available languages field" do
        expect {
          service.synchronize_archived_welsh_form
        }.to change { form.reload.latest_form_document.content["available_languages"] }.from(%w[en cy]).to(%w[en])
        .and change { form.reload.form_documents.count }.by(1)
        .and change { form.reload.latest_form_document.version }.by(1)
      end

      it "does not change the available languages in the existing live English form document" do
        expect {
          service.synchronize_archived_welsh_form
        }.to not_change { live_form_document_en.reload.content["available_languages"] }.from(%w[en cy])
      end
    end
  end

  describe "#update_draft_form_document" do
    context "when there is no draft form document" do
      before do
        form.draft_form_document.destroy
      end

      it "creates a draft form document" do
        expect {
          service.update_draft_form_document
        }.to(change { FormDocument.exists?(form:, tag: "draft") }.from(false).to(true))
      end

      it "creates a draft form document without a version" do
        service.update_draft_form_document
        expect(FormDocument.find_by(form:, tag: "draft", language: "en").version).to be_nil
      end

      it "does not set the latest_form_document_id" do
        service.update_draft_form_document
        expect(form.reload.latest_form_document_id).to be_nil
      end

      context "when there is a declaration in Welsh but not in English translations" do
        let(:form) { create(:form, available_languages: %w[en cy], declaration_markdown: "", declaration_markdown_cy: "Shouldn't be here") }

        it "does not include the declaration in Welsh" do
          service.update_draft_form_document
          welsh_form_document = FormDocument.find_by(form:, tag: "draft", language: "cy")
          expect(welsh_form_document.content).to include("declaration_markdown" => nil)
        end
      end

      context "when there is hint test in Welsh but not in English translations" do
        let(:form) { create(:form, available_languages: %w[en cy], pages: [create(:page, hint_text: "", hint_text_cy: "Shouldn't be here")]) }

        it "does not include the hint text in Welsh" do
          service.update_draft_form_document
          welsh_form_document = FormDocument.find_by(form:, tag: "draft", language: "cy")
          expect(welsh_form_document.content["steps"].first["data"]).to include("hint_text" => nil)
        end
      end
    end

    context "when there is a draft form document" do
      let!(:form_document) { form.draft_form_document }
      let(:new_name) { "new name" }

      before do
        form.name = new_name
      end

      it "updates the draft form document" do
        expect {
          service.update_draft_form_document
        }.to change { form_document.reload.content["name"] }.to(new_name)
      end

      it "does not set a version on the draft form document" do
        service.update_draft_form_document
        expect(form_document.reload.version).to be_nil
      end

      context "when there is also a live form document" do
        let!(:live_form_document) { create :form_document, :live, form:, content: "content" }

        it "does not modify the live form document" do
          expect {
            service.update_draft_form_document
          }.not_to(change { live_form_document.reload.content })
        end
      end

      context "when there is a draft form document in welsh" do
        before do
          create :form_document, :draft, form:, content: "content", language: "cy"
        end

        it "removes the draft form document in welsh" do
          expect {
            service.update_draft_form_document
          }.to(change { FormDocument.exists?(form:, tag: "draft", language: "cy") }.from(true).to(false))
        end
      end
    end
  end

  describe "#synchronize_only_live_english_form" do
    let!(:form) { create(:form, state: "live") }
    let(:expected_live_at) { form.reload.updated_at.as_json }

    context "when there is no existing form document" do
      it "creates a live form document" do
        expect {
          service.synchronize_only_live_english_form
        }.to change(FormDocument, :count).by(1)

        expect(FormDocument.order(version: :desc).last).to have_attributes(form:, tag: "live", content: form.as_form_document(live_at: expected_live_at), version: 1)
      end

      it "sets the latest_form_document_id on the form" do
        service.synchronize_only_live_english_form
        expect(form.reload.latest_form_document_id).to eq(FormDocument.order(version: :desc).find_by(form:, tag: "live", language: "en").id)
      end
    end

    context "when there is an existing live form document" do
      let!(:form_document) { create :form_document, :live, form:, content: form.as_form_document }

      before do
        form.latest_form_document = form_document
        form.save!
      end

      it "updates the live form document" do
        new_name = "new name"
        form.name = new_name
        form.save!

        expect {
          service.synchronize_only_live_english_form
        }.to change { form.reload.latest_form_document.content["name"] }.to(new_name)
      end

      it "sets the live_at date in the new form document" do
        service.synchronize_only_live_english_form
        expect(FormDocument.last["content"]).to include("live_at" => form.reload.updated_at.as_json)
      end

      it "creates a new English form document with an incremented version" do
        expect {
          service.synchronize_only_live_english_form
        }.to change { form.reload.latest_form_document.version }.by(1)
      end

      it "does not change the existing form document's version" do
        expect {
          service.synchronize_only_live_english_form
        }.not_to(change { form_document.reload.version })
      end
    end

    context "when there is an existing archived form document" do
      before do
        create :form_document, :archived, form:
      end

      it "destroys the archived form document" do
        expect {
          service.synchronize_only_live_english_form
        }.to(change { FormDocument.exists?(form:, tag: "archived") }.from(true).to(false))
      end

      it "creates the live form document" do
        expect {
          service.synchronize_only_live_english_form
        }.to(change { FormDocument.exists?(form:, tag: "live", version: 1) }.from(false).to(true))
      end

      context "and deleting the archived FormDocument fails" do
        before do
          allow(service).to receive(:delete_form_documents_by_tag).with(FormDocumentSyncService::ARCHIVED_TAG)
            .and_raise(ActiveRecord::StatementInvalid)
        end

        it "does not create the live FormDocument" do
          expect {
            service.synchronize_only_live_english_form
          }.to raise_error(ActiveRecord::StatementInvalid).and not_change(FormDocument, :count)
        end
      end
    end

    context "when the form has welsh translations" do
      let(:form) { create(:form, state: "live", available_languages: %w[en cy]) }

      it "only creates a live English form document" do
        expect {
          service.synchronize_only_live_english_form
        }.to change { FormDocument.where(form:, tag: "live", language: "en").count }.by(1)

        expect(FormDocument.where(form:, tag: "live", language: "en")).to exist
        expect(FormDocument.where(form:, tag: "live", language: "en").first.content["available_languages"]).to eq %w[en]
        expect(FormDocument.where(form:, tag: "live", language: "en").first.version).to eq 1
        expect(FormDocument.where(form:, tag: "live", language: "cy")).not_to exist
      end

      context "and the English form fails to save" do
        before do
          allow(service).to receive(:create_new_versioned_form_document)
            .with("live", anything, "en", anything)
            .and_raise(ActiveRecord::RecordInvalid.new(form), "simulated FormDocument saving error")
        end

        it "does not create any FormDocuments" do
          expect {
            service.synchronize_only_live_english_form
          }.to raise_error(ActiveRecord::RecordInvalid).and not_change(FormDocument, :count)
        end
      end
    end

    context "when there is already a live Welsh form document" do
      before do
        create :form_document, :live, form:, language: "cy", content: { "available_languages" => %w[en cy] }
      end

      it "does not create any FormDocuments" do
        expect {
          service.synchronize_only_live_english_form
        }.to raise_error(ActiveRecord::RecordNotFound).and not_change(FormDocument, :count)
      end
    end
  end

  describe "#synchronize_only_live_welsh_form" do
    let!(:form) { create(:form, :with_welsh_translation, :ready_for_live, state: "live", available_languages: %w[en]) }
    let(:expected_live_at) { form.reload.updated_at.as_json }
    let(:welsh_form_content) do
      Mobility.with_locale(:cy) do
        form.as_form_document(live_at: expected_live_at, language: :cy)
      end
    end

    context "when there is a live English form document" do
      before do
        form_document = create :form_document, :live, form:, language: "en", content: form.as_form_document
        form.latest_form_document_id = form_document.id
        form.available_languages = %w[en cy]
        form.save!
      end

      context "when there is no existing Welsh form document" do
        it "creates a live Welsh form document" do
          expect {
            service.synchronize_only_live_welsh_form
          }.to change { FormDocument.exists?(form:, tag: "live", language: "cy") }.from(false).to(true)

          welsh_form_document = form.reload.latest_welsh_form_document
          expect(welsh_form_document.content["available_languages"]).to eq %w[en cy]
          expect(welsh_form_document.version).to eq 2
          expect(welsh_form_document).to have_attributes(form:, tag: "live", content: welsh_form_content)
        end

        it "creates a new English form document with only the available_languages field changed from the previous live document" do
          new_name = "New name"
          form.name = new_name
          form.save!

          expect {
            service.synchronize_only_live_welsh_form
          }.to change { FormDocument.where(form:, tag: "live", language: "en").count }.by(1)
          .and change { form.reload.latest_form_document.version }.by(1)
          .and change { form.reload.latest_form_document.content["available_languages"] }.to(%w[en cy])
          .and not_change { form.reload.latest_form_document.content["name"] }
          .and(not_change { form.reload.latest_form_document.content["live_at"] })
        end

        it "updates the latest_live_form_document_id" do
          expect {
            service.synchronize_only_live_welsh_form
          }.to(change { form.reload.latest_form_document_id })
        end
      end

      context "when there is an existing live Welsh form document" do
        let!(:form_document) { create :form_document, :live, form:, language: "cy", content: welsh_form_content, version: 1 }

        it "creates a new live Welsh form document with the new content" do
          new_name = "new name"
          form.name_cy = new_name
          form.save!

          expect {
            service.synchronize_only_live_welsh_form
          }.to change { form.reload.latest_welsh_form_document.content["name"] }.to(new_name)
        end

        it "sets the live_at date in the new form document" do
          service.synchronize_only_live_welsh_form
          expect(form.reload.latest_welsh_form_document.content).to include("live_at" => form.reload.updated_at.as_json)
        end

        it "increments the English and Welsh versions by 1" do
          service.synchronize_only_live_welsh_form
          expect(form.reload.latest_form_document.version).to eq(2)
          expect(form.reload.latest_welsh_form_document.version).to eq(2)
        end
      end

      context "when there is an existing archived Welsh form document" do
        before do
          create :form_document, :archived, form:, language: "cy"
        end

        it "destroys the archived form document" do
          expect {
            service.synchronize_only_live_welsh_form
          }.to(change { FormDocument.exists?(form:, tag: "archived", language: "cy") }.from(true).to(false))
        end

        it "creates the live form document" do
          expect {
            service.synchronize_only_live_welsh_form
          }.to(change { FormDocument.exists?(form:, tag: "live", language: "cy") }.from(false).to(true))
        end

        context "and deleting the archived FormDocument fails" do
          before do
            allow(service).to receive(:delete_form_documents_by_tag).with(FormDocumentSyncService::ARCHIVED_TAG)
              .and_raise(ActiveRecord::StatementInvalid)
          end

          it "does not create the live FormDocument" do
            expect {
              service.synchronize_only_live_welsh_form
            }.to raise_error(ActiveRecord::StatementInvalid).and not_change(FormDocument, :count)
          end
        end
      end
    end

    context "when there is no live English form document" do
      it "does not create any FormDocuments" do
        expect {
          service.synchronize_only_live_welsh_form
        }.to raise_error(ActiveRecord::RecordNotFound).and not_change(FormDocument, :count)
      end
    end
  end
end
