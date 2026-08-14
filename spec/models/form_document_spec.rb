require "rails_helper"

RSpec.describe FormDocument, type: :model do
  it "is valid with valid attributes" do
    form_document = build(:form_document)
    expect(form_document).to be_valid
  end

  it "is invalid without a form" do
    form_document = build(:form_document, form: nil)
    expect(form_document).not_to be_valid
  end

  it "is invalid without a tag" do
    form_document = build(:form_document, tag: nil)
    expect(form_document).not_to be_valid
  end

  it "is invalid without langauage" do
    form_document = build(:form_document, language: nil)
    expect(form_document).to be_invalid
  end

  it "is invalid with a language that is not supported" do
    form_document = build(:form_document, language: "zz")
    expect(form_document).to be_invalid
  end

  it "is valid with a supported language" do
    form_document = build(:form_document, language: "cy")
    expect(form_document).to be_valid
  end

  it "has a default created_at and updated_at" do
    travel_to Time.zone.local(2023, 10, 1, 10, 0, 0) do
      form_document = create(:form_document, :live)

      expect(form_document.created_at).to eq(Time.zone.now)
      expect(form_document.updated_at).to eq(Time.zone.now)
    end
  end

  it "belongs to a Form" do
    form_document = build(:form_document)

    expect(form_document.form).to be_a(Form)
  end

  it "raises an error if a form document with the same version exists for the form" do
    form_document = create(:form_document, :live, version: 1)
    expect { create(:form_document, :archived, form: form_document.form, version: 1) }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "raises an error if a draft form document already exists for the form" do
    form = create(:form) # also creates a draft form document
    expect { create(:form_document, :draft, form: form) }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "allows creating a form with the same version and a different language" do
    form_document = create(:form_document, :live, language: "en")
    expect { create(:form_document, :live, form: form_document.form, language: "cy") }.not_to raise_error
  end

  it "allows creating a draft form with a different language" do
    form = create(:form) # also creates a draft form document
    expect { create(:form_document, :draft, form: form, language: "cy") }.not_to raise_error
  end

  describe ".latest_live_or_archived" do
    let(:form) { create :form }

    context "when the form only has a draft form document" do
      it "returns nil" do
        expect(form.draft_form_document).to be_present
        expect(described_class.latest_live_or_archived(form_id: form.id, language: "en")).to be_nil
      end
    end

    context "when there is one form document with a version" do
      let!(:form_document) { create :form_document, :live, form:, language: "en", version: 1 }

      it "returns the form document" do
        expect(described_class.latest_live_or_archived(form_id: form.id, language: "en")).to eq(form_document)
      end

      it "returns nil when no form document for the language exists" do
        expect(described_class.latest_live_or_archived(form_id: form.id, language: "cy")).to be_nil
      end
    end

    context "when there are multiple form documents with different versions" do
      let(:latest_document) { create :form_document, :archived, form:, language: "en", version: 3 }

      before do
        create :form_document, :live, form:, language: "en", version: 1
        latest_document
        create :form_document, :live, form:, language: "en", version: 2
      end

      it "returns the latest form document with the highest version" do
        expect(described_class.latest_live_or_archived(form_id: form.id, language: "en")).to eq(latest_document)
      end
    end

    context "when there are form documents for different languages" do
      let(:latest_english_document) { create :form_document, form:, language: "en", version: 2 }
      let(:latest_welsh_document) { create :form_document, form:, language: "cy", version: 1 }

      before do
        create :form_document, form:, language: "en", version: 1
        latest_english_document
        latest_welsh_document
      end

      it "returns the latest English document regardless of Welsh versions" do
        expect(described_class.latest_live_or_archived(form_id: form.id, language: "en")).to eq(latest_english_document)
      end

      it "returns the latest Welsh document regardless of English versions" do
        expect(described_class.latest_live_or_archived(form_id: form.id, language: "cy")).to eq(latest_welsh_document)
      end
    end

    context "when documents from other forms exist" do
      let(:other_form) { create :form }
      let!(:other_form_document) { create :form_document, :live, form: other_form, language: "en", version: 2 }
      let!(:this_form_document) { create :form_document, :live, form:, language: "en", version: 1 }

      it "only returns documents from the current form" do
        expect(described_class.latest_live_or_archived(form_id: form.id, language: "en")).to eq(this_form_document)
        expect(described_class.latest_live_or_archived(form_id: other_form.id, language: "en")).to eq(other_form_document)
      end
    end
  end
end
