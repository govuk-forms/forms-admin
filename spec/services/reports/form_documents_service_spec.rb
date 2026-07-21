require "rails_helper"

RSpec.describe Reports::FormDocumentsService do
  let(:form_with_no_routes) { create(:form, :live) }
  let(:draft_form) { create(:form) }
  let(:archived_form) { create(:form, :archived) }
  let(:live_with_draft_form) { create(:form, :live_with_draft) }
  let(:archived_with_draft_form) { create(:form, :archived_with_draft) }
  let(:draft_internal_organisation_form) { create :form }
  let(:live_internal_organisation_form) { create :form }
  let(:form_with_welsh_translation) { create :form, welsh_completed: true }
  let(:branch_route_form) do
    form = create(:form, :live, :ready_for_routing)
    create(:condition, :with_exit_page, routing_page_id: form.pages[0].id, check_page_id: form.pages[0].id, answer_value: "Option 1")
    create(:condition, routing_page_id: form.pages[1].id, check_page_id: form.pages[1].id, answer_value: "Option 1", goto_page_id: form.pages[3].id)
    create(:condition, routing_page_id: form.pages[2].id, check_page_id: form.pages[1].id, goto_page_id: form.pages[4].id)
    form.live_form_document.update!(content: form.reload.as_form_document(live_at: form.updated_at))
    form
  end

  let(:basic_route_form) do
    form = create(:form, :live, :ready_for_routing)
    create(:condition, routing_page_id: form.pages.first.id, check_page_id: form.pages.first.id, answer_value: "Option 1", skip_to_end: true)
    form.live_form_document.update!(content: form.reload.as_form_document(live_at: form.updated_at))
    form
  end

  let(:form_with_2_branch_routes) do
    form = create(:form, :live, :ready_for_routing, pages_count: 10)
    create(:condition, routing_page_id: form.pages[1].id, check_page_id: form.pages[1].id, answer_value: "Option 1", goto_page_id: form.pages[3].id)
    create(:condition, routing_page_id: form.pages[2].id, check_page_id: form.pages[1].id, answer_value: "Option 2", goto_page_id: form.pages[4].id)
    create(:condition, routing_page_id: form.pages[6].id, check_page_id: form.pages[6].id, answer_value: "Option 1", goto_page_id: form.pages[8].id)
    create(:condition, routing_page_id: form.pages[7].id, check_page_id: form.pages[6].id, answer_value: "Option 2", goto_page_id: form.pages[9].id)
    form.live_form_document.update!(content: form.reload.as_form_document(live_at: form.updated_at))
    form
  end

  describe "#form_documents" do
    let(:organisation) { create :organisation, internal: false, slug: "hm-revenue-customs" }
    let(:internal_organisation) { create :organisation, internal: true, slug: "internal-org" }
    let(:group) { create :group, organisation: }
    let(:internal_group) { create :group, organisation: internal_organisation }

    before do
      group.group_forms.create!(form: form_with_no_routes)
      group.group_forms.create!(form: draft_form)
      group.group_forms.create!(form: archived_form)
      group.group_forms.create!(form: live_with_draft_form)
      group.group_forms.create!(form: archived_with_draft_form)
      internal_group.group_forms.create!(form: draft_internal_organisation_form)
      internal_group.group_forms.create!(form: live_internal_organisation_form)
    end

    context "when the tag is draft" do
      let(:tag) { "draft" }

      it "returns an Enumerator" do
        expect(described_class.form_documents(tag:)).to be_a(Enumerator)
      end

      it "returns form documents when the Enumerator is evaluated" do
        form_document = described_class.form_documents(tag:).first
        expect(form_document).to be_a(Hash)
        expect(form_document).to have_key("form_id")
      end

      it "only includes draft form documents from external organisations" do
        form_documents = described_class.form_documents(tag:)
        expect(form_documents.map { |form_document| form_document["form_id"] }.to_a)
          .to contain_exactly(draft_form.id, live_with_draft_form.id, archived_with_draft_form.id)
      end

      it "includes the group and organisation details" do
        form_document = described_class.form_documents(tag:).first
        expect(form_document).to include(
          "organisation_name" => group.organisation.name,
          "organisation_id" => group.organisation.id,
          "group_name" => group.name,
          "group_external_id" => group.external_id,
        )
      end

      context "when there is a welsh translation" do
        let!(:live_with_draft_form_and_welsh) { create(:form, :live_with_draft, :with_welsh_translation, :with_group, group:) }

        it "does not include the welsh translation form document" do
          form_documents = described_class.form_documents(tag:)
          expect(form_documents.pluck("language").to_a).to all(eq "en")
          expect(form_documents.map { |form_document| form_document["form_id"] }.to_a)
            .to contain_exactly(draft_form.id, live_with_draft_form.id, live_with_draft_form_and_welsh.id, archived_with_draft_form.id)
        end
      end
    end

    context "when the tag is live" do
      let(:tag) { "live" }

      it "only includes live form documents from external organisations" do
        form_documents = described_class.form_documents(tag:)
        expect(form_documents.map { |form_document| form_document["form_id"] }.to_a)
          .to contain_exactly(
            form_with_no_routes.id,
            live_with_draft_form.id,
          )
      end
    end

    context "when the tag is live-or-archived" do
      let(:tag) { "live-or-archived" }

      it "only includes live or archived form documents from external organisations" do
        form_documents = described_class.form_documents(tag:)
        expect(form_documents.map { |form_document| form_document["form_id"] }.to_a)
          .to contain_exactly(
            form_with_no_routes.id,
            live_with_draft_form.id,
            archived_form.id,
            archived_with_draft_form.id,
          )
      end
    end
  end

  describe ".has_secondary_skip_routes?" do
    subject(:count_secondary_skip_routes) do
      described_class.has_secondary_skip_routes?(form_document)
    end

    context "when form has one step with one secondary skip condition" do
      let(:form_document) { branch_route_form.live_form_document }

      it { is_expected.to be true }
    end

    context "when form has two steps each with one secondary skip condition" do
      let(:form_document) { form_with_2_branch_routes.live_form_document }

      it { is_expected.to be true }
    end

    context "when form has no secondary skip conditions" do
      let(:form_document) { basic_route_form.live_form_document }

      it { is_expected.to be false }
    end
  end

  describe ".count_secondary_skip_routes" do
    subject(:count_secondary_skip_routes) do
      described_class.count_secondary_skip_routes(form_document)
    end

    context "when form has one step with one secondary skip condition" do
      let(:form_document) { branch_route_form.live_form_document }

      it { is_expected.to eq 1 }
    end

    context "when form has two steps each with one secondary skip condition" do
      let(:form_document) { form_with_2_branch_routes.live_form_document }

      it { is_expected.to eq 2 }
    end

    context "when form has no secondary skip conditions" do
      let(:form_document) { basic_route_form.live_form_document }

      it { is_expected.to eq 0 }
    end
  end

  describe ".step_has_secondary_skip_route?" do
    context "when step is check page for secondary skip condition" do
      let(:form_document) { branch_route_form.live_form_document }
      let(:step) { form_document["content"]["steps"][1] }

      it "returns true" do
        expect(described_class.step_has_secondary_skip_route?(form_document, step)).to be true
      end
    end

    context "when step is not check page for secondary skip condition" do
      let(:form_document) { branch_route_form.live_form_document }
      let(:step) { form_document["content"]["steps"][3] }

      it "returns false" do
        expect(described_class.step_has_secondary_skip_route?(form_document, step)).to be false
      end
    end

    context "when form has no secondary skip conditions" do
      let(:form_document) { basic_route_form.live_form_document }
      let(:step) { form_document["content"]["steps"][0] }

      it "returns false" do
        expect(described_class.step_has_secondary_skip_route?(form_document, step)).to be false
      end
    end
  end

  describe ".has_exit_pages?" do
    subject(:has_exit_pages?) do
      described_class.has_exit_pages?(form_document)
    end

    context "when form has one step with one exit page" do
      let(:form_document) { branch_route_form.live_form_document }

      it { is_expected.to be true }
    end

    context "when form has no exit pages" do
      let(:form_document) { basic_route_form.live_form_document }

      it { is_expected.to be false }
    end
  end

  describe ".has_add_another_answer?" do
    let(:form) do
      create(:form, :live, pages: [
        create(:page, is_repeatable:),
      ])
    end
    let(:form_document) { form.live_form_document }

    context "when the form has a question with add another answer" do
      let(:is_repeatable) { true }

      it "returns true" do
        expect(described_class.has_add_another_answer?(form_document)).to be true
      end
    end

    context "when the form does not have a question with add another answer" do
      let(:is_repeatable) { false }

      it "returns false" do
        expect(described_class.has_add_another_answer?(form_document)).to be false
      end
    end
  end

  describe ".has_daily_submission_csv" do
    subject(:daily_submission_batch_enabled) do
      described_class.has_daily_submission_csv(form_document)
    end

    context "when form has a daily delivery_configuration" do
      let(:form_document) do
        create(:form, :live, delivery_configurations: [create(:delivery_configuration, :daily_email)])
          .live_form_document
      end

      it "returns true" do
        expect(daily_submission_batch_enabled).to be true
      end
    end

    context "when form does not have a daily delivery_configuration" do
      let(:form_document) { create(:form, :live).live_form_document }

      it "returns false" do
        expect(daily_submission_batch_enabled).to be false
      end
    end
  end

  describe ".has_weekly_submission_csv" do
    subject(:weekly_submission_batch_enabled) do
      described_class.has_weekly_submission_csv(form_document)
    end

    context "when form has weekly delivery_configuration" do
      let(:form_document) do
        create(:form, :live, delivery_configurations: [create(:delivery_configuration, :weekly_email)])
          .live_form_document
      end

      it "returns true" do
        expect(weekly_submission_batch_enabled).to be true
      end
    end

    context "when form does not have a weekly delivery_configuration" do
      let(:form_document) { create(:form, :live).live_form_document }

      it "returns false" do
        expect(weekly_submission_batch_enabled).to be false
      end
    end
  end

  describe ".has_welsh_translation" do
    subject(:has_welsh_translation) do
      described_class.has_welsh_translation(form_document)
    end

    context "when form has a welsh translation" do
      it "returns true" do
        expect(described_class.has_welsh_translation(form_with_welsh_translation)).to be true
      end
    end
  end
end
