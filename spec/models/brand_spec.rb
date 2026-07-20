require "rails_helper"

RSpec.describe Brand, type: :model do
  subject(:brand) { build :brand }

  it "is invalid without a slug" do
    brand.slug = nil
    expect(brand).to be_invalid
    expect(brand.errors).to be_of_kind(:slug, :blank)
  end

  it "is invalid without a name" do
    brand.name = nil
    expect(brand).to be_invalid
    expect(brand.errors).to be_of_kind(:name, :blank)
  end

  it "is invalid when the slug is not kebab-case" do
    ["Testshire", "testshire council", "testshire_council", " testshire", "testshire-"].each do |slug|
      brand.slug = slug
      expect(brand).to be_invalid
      expect(brand.errors).to be_of_kind(:slug, :invalid)
    end
  end

  it "is valid with a kebab-case slug" do
    brand.slug = "testshire-east-2"
    expect(brand).to be_valid
  end

  it "is invalid with a duplicate slug" do
    create(:brand, slug: "duplicate-brand")
    brand.slug = "duplicate-brand"
    expect(brand).to be_invalid
    expect(brand.errors).to be_of_kind(:slug, :taken)
  end

  it "is an error to insert a brand with an existing slug" do
    existing_brand = create(:brand)

    expect {
      described_class.insert!({ slug: existing_brand.slug, name: existing_brand.name, created_at: Time.zone.now, updated_at: Time.zone.now })
    }.to raise_error ActiveRecord::RecordNotUnique
  end
end
