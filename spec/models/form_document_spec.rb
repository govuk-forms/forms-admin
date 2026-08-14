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
end
