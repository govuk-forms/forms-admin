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

  %i[header_background_colour border_colour logo_alt_text logo_link copyright_holder].each do |attribute|
    it "is invalid without a #{attribute.to_s.humanize.downcase}" do
      brand.public_send("#{attribute}=", nil)
      expect(brand).to be_invalid
      expect(brand.errors).to be_of_kind(attribute, :blank)
    end
  end

  %i[header_background_colour border_colour].each do |attribute|
    it "is invalid when the #{attribute.to_s.humanize.downcase} is not a lowercase 6-digit hex colour code" do
      ["ffffff", "#FFFFFF", "#fff", "#gggggg", "white"].each do |colour|
        brand.public_send("#{attribute}=", colour)
        expect(brand).to be_invalid
        expect(brand.errors).to be_of_kind(attribute, :invalid)
      end
    end

    it "is valid when the #{attribute.to_s.humanize.downcase} is a lowercase 6-digit hex colour code" do
      brand.public_send("#{attribute}=", "#0b0c0c")
      expect(brand).to be_valid
    end
  end

  it "is invalid when the logo link does not start with http:// or https://" do
    ["www.example.com", "example.com", "ftp://example.com"].each do |url|
      brand.logo_link = url
      expect(brand).to be_invalid
      expect(brand.errors).to be_of_kind(:logo_link, :invalid)
    end
  end

  it "is invalid when the logo link contains more than one line" do
    brand.logo_link = "https://www.example.com\nmalicious"
    expect(brand).to be_invalid
    expect(brand.errors).to be_of_kind(:logo_link, :invalid)
  end

  it "is valid when the logo link starts with https://" do
    brand.logo_link = "https://www.example.com"
    expect(brand).to be_valid
  end

  describe "asset file validation" do
    {
      logo_file: %w[logo.png logo.jpeg],
      favicon_file: %w[favicon.ico logo.png],
      opengraph_image_file: %w[logo.png logo.jpeg],
    }.each do |attribute, fixtures|
      fixtures.each do |fixture|
        it "is valid when the #{attribute.to_s.humanize.downcase} is #{File.extname(fixture).delete('.').upcase}" do
          brand.public_send("#{attribute}=", Rack::Test::UploadedFile.new(file_fixture(fixture)))
          expect(brand).to be_valid
        end
      end

      it "is invalid when the #{attribute.to_s.humanize.downcase} is not an allowed file type" do
        brand.public_send("#{attribute}=", Rack::Test::UploadedFile.new(file_fixture("invalid.txt"), "text/plain"))
        expect(brand).to be_invalid
        expect(brand.errors).to be_of_kind(attribute, :invalid_file_type)
      end
    end

    it "is invalid when the opengraph image is an ICO file" do
      brand.opengraph_image_file = Rack::Test::UploadedFile.new(file_fixture("favicon.ico"))
      expect(brand).to be_invalid
      expect(brand.errors).to be_of_kind(:opengraph_image_file, :invalid_file_type)
    end
  end

  it "is an error to insert a brand with an existing slug" do
    existing_brand = create(:brand)

    expect {
      described_class.insert!({ slug: existing_brand.slug, name: existing_brand.name, created_at: Time.zone.now, updated_at: Time.zone.now })
    }.to raise_error ActiveRecord::RecordNotUnique
  end
end
