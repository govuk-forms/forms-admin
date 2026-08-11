require "rails_helper"

RSpec.describe "data_migrations.rake", type: :task do
  describe "data_migrations:set_version_on_form_documents" do
    subject(:task) do
      Rake::Task["data_migrations:set_version_on_form_documents"]
    end

    context "when the version is not set for form documents" do
      let!(:live_form) { create :form, :live, :with_welsh_translation }
      let!(:archived_form) { create :form, :archived, :with_welsh_translation }
      let!(:draft_form) { create :form, :with_welsh_translation }

      before do
        live_form.live_form_document.update!(version: nil)
        live_form.live_welsh_form_document.update!(version: nil)
        archived_form.archived_form_document.update!(version: nil)
        archived_form.archived_welsh_form_document.update!(version: nil)
      end

      it "sets version to 1 for all live and archived form documents" do
        task.invoke

        expect(live_form.live_form_document.reload.version).to eq(1)
        expect(live_form.live_welsh_form_document.reload.version).to eq(1)
        expect(archived_form.archived_form_document.reload.version).to eq(1)
        expect(archived_form.archived_welsh_form_document.reload.version).to eq(1)
      end

      it "does not set version for draft form documents" do
        task.invoke

        expect(draft_form.draft_form_document.reload.version).to be_nil
        expect(draft_form.draft_welsh_form_document.reload.version).to be_nil
      end

      it "updates latest_form_document_id to the English version" do
        task.invoke

        expect(live_form.reload.latest_form_document_id).to eq(live_form.live_form_document.id)
        expect(archived_form.reload.latest_form_document_id).to eq(archived_form.archived_form_document.id)
      end

      it "does not update the latest_form_document_id for draft forms" do
        task.invoke

        expect(draft_form.reload.latest_form_document_id).to be_nil
      end
    end

    context "when the version is set for form documents" do
      let!(:live_form) { create :form, :live, :with_welsh_translation }

      before do
        live_form.live_form_document.update!(version: 2)
        live_form.live_welsh_form_document.update!(version: 2)
      end

      it "does not change the version for form documents that already have a version set" do
        task.invoke

        expect(live_form.live_form_document.reload.version).to eq(2)
        expect(live_form.live_welsh_form_document.reload.version).to eq(2)
      end
    end
  end
end
