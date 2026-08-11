require "rails_helper"

RSpec.describe FormDocument::Content, type: :model do
  subject(:form_document_content) { described_class.from_form_document(form_document) }

  let(:form) { create :form, :live }
  let(:form_document) { form.live_form_document }

  it "ignores any attributes that are not defined" do
    expect(described_class.new(foo: "bar").attributes).not_to include(:foo)
  end

  describe "#made_live_date" do
    let(:form_document) do
      form.live_form_document.tap do |form_document|
        form_document.content["first_made_live_at"] = first_made_live_at
      end
    end

    context "when the first_made_live_at date is not set" do
      let(:first_made_live_at) { nil }

      it "returns nil" do
        expect(form_document_content.made_live_date).to be_nil
      end
    end

    context "when first_made_live_at is set" do
      let(:first_made_live_at) { Time.zone.local(2021, 3, 3, 4, 4, 4) }

      it "returns the first_made_live_at date" do
        expect(form_document_content.made_live_date).to eq(Time.zone.local(2021, 3, 3))
      end
    end
  end

  it "has all form attributes the original form has" do
    excluded_attributes = %w[id
                             state
                             external_id
                             pages
                             question_section_completed
                             declaration_section_completed
                             share_preview_completed
                             welsh_completed
                             copied_from_id
                             submission_type
                             submission_format
                             send_daily_submission_batch
                             send_weekly_submission_batch
                             latest_form_document_id]
    expected_attributes = form.attributes.except(*excluded_attributes)
    expect(form_document_content).to have_attributes(expected_attributes)
  end

  it "has a form_id" do
    expect(form_document_content).to have_attributes("form_id" => form.id)
  end

  describe "#steps" do
    it "defaults to an empty array" do
      expect(described_class.new).to have_attributes(steps: [])
    end

    context "when the form has pages" do
      let(:form) { create :form, :live, :with_pages }

      it "converts attributes for steps to a model" do
        expect(form_document_content.steps).to all be_a FormDocument::Step
        expect(form_document_content.steps.count).to eq(form.pages.count)
      end
    end
  end

  describe ".from_form_document" do
    let(:form) { create :form, :live }
    let(:form_document) { form.live_form_document }

    it "creates a FormDocument::Content" do
      expect(described_class.from_form_document(form_document)).to be_a(described_class)
    end
  end

  describe "#has_welsh_translation?" do
    context "when available_languages includes Welsh" do
      let(:form) { create :form, :live, available_languages: %w[en cy] }

      it "returns true" do
        expect(form_document_content.has_welsh_translation?).to be true
      end
    end

    context "when available_languages does not include Welsh" do
      let(:form) { create :form, :live, available_languages: %w[en] }

      it "returns false" do
        expect(form_document_content.has_welsh_translation?).to be false
      end
    end

    context "when available_languages is not set" do
      let(:form_document) { form.live_form_document }

      it "returns false" do
        form_document.content.delete("available_languages")
        expect(form_document_content.has_welsh_translation?).to be false
      end
    end
  end
end
