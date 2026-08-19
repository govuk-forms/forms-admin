require "rails_helper"

RSpec.describe BrandAssetsService do
  subject(:service) { described_class.new(brand:) }

  let(:brand) { create :brand }

  describe "#attach_assets" do
    it "attaches nothing when no files have been set" do
      service.attach_assets

      expect(brand.logo).not_to be_attached
      expect(brand.favicon).not_to be_attached
      expect(brand.opengraph_image).not_to be_attached
    end

    it "uploads each file as a blob with a public asset key" do
      brand.logo_file = Rack::Test::UploadedFile.new(file_fixture("logo.png"))
      brand.favicon_file = Rack::Test::UploadedFile.new(file_fixture("favicon.ico"))
      brand.opengraph_image_file = Rack::Test::UploadedFile.new(file_fixture("logo.jpeg"))

      service.attach_assets

      expect(brand.logo.blob.key).to match(%r{\Aassets/brands/#{brand.slug}/logo-\h{6}\.png\z})
      expect(brand.favicon.blob.key).to match(%r{\Aassets/brands/#{brand.slug}/favicon-\h{6}\.ico\z})
      expect(brand.opengraph_image.blob.key).to match(%r{\Aassets/brands/#{brand.slug}/opengraph-image-\h{6}\.jpg\z})
    end

    it "sets the blob content type from the file contents, not the declared type" do
      brand.logo_file = Rack::Test::UploadedFile.new(file_fixture("logo.png"), "application/octet-stream")

      service.attach_assets

      expect(brand.logo.blob.content_type).to eq "image/png"
    end

    it "uploads the file contents" do
      brand.logo_file = Rack::Test::UploadedFile.new(file_fixture("logo.png"))

      service.attach_assets

      expect(brand.logo.blob.download).to eq file_fixture("logo.png").binread
    end

    it "replaces an existing asset with a new key" do
      brand.logo_file = Rack::Test::UploadedFile.new(file_fixture("logo.png"))
      service.attach_assets
      original_key = brand.logo.blob.key

      brand.logo_file = Rack::Test::UploadedFile.new(file_fixture("logo.jpeg"))
      described_class.new(brand:).attach_assets

      expect(brand.reload.logo.blob.key).to match(%r{\Aassets/brands/#{brand.slug}/logo-\h{6}\.jpg\z})
      expect(brand.logo.blob.key).not_to eq original_key
    end

    it "leaves other assets unchanged when only one file is set" do
      brand.favicon_file = Rack::Test::UploadedFile.new(file_fixture("favicon.ico"))
      service.attach_assets
      favicon_key = brand.favicon.blob.key

      brand.favicon_file = nil
      brand.logo_file = Rack::Test::UploadedFile.new(file_fixture("logo.png"))
      described_class.new(brand:).attach_assets

      expect(brand.reload.favicon.blob.key).to eq favicon_key
    end
  end
end
