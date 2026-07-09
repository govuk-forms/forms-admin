require "rails_helper"

RSpec.describe Brand, type: :model do
  subject(:brand) { build :brand }

  it "has a valid factory" do
    expect(brand).to be_valid
  end

  it "is invalid without a slug" do
    brand.slug = nil
    expect(brand).to be_invalid
    expect(brand.errors[:slug]).to include("can't be blank")
  end

  it "is invalid without a name" do
    brand.name = nil
    expect(brand).to be_invalid
    expect(brand.errors[:name]).to include("can't be blank")
  end

  it "is invalid with a duplicate slug" do
    create(:brand, slug: "duplicate-brand")
    brand.slug = "duplicate-brand"
    expect(brand).to be_invalid
    expect(brand.errors[:slug]).to include("has already been taken")
  end

  it "is an error to create a brand with an existing slug" do
    existing_brand = create(:brand)

    expect {
      described_class.insert!({ slug: existing_brand.slug, name: existing_brand.name, created_at: Time.zone.now, updated_at: Time.zone.now })
    }.to raise_error ActiveRecord::RecordNotUnique
  end
end
