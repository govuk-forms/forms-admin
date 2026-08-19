class BrandAssetsService
  FILE_EXTENSIONS = {
    "image/png" => "png",
    "image/jpeg" => "jpg",
    "image/vnd.microsoft.icon" => "ico",
    "image/x-icon" => "ico",
  }.freeze

  def initialize(brand:)
    @brand = brand
  end

  def attach_assets
    Brand::ASSET_CONTENT_TYPES.each_key do |asset_name|
      file = @brand.public_send(:"#{asset_name}_file")
      attach(asset_name, file) if file.present?
    end
  end

private

  def attach(asset_name, file)
    content_type = FileContentTypeValidator.content_type(file)
    file.rewind

    blob = ActiveStorage::Blob.create_and_upload!(
      io: file,
      filename: file.original_filename,
      content_type:,
      identify: false,
      key: key_for(asset_name, content_type),
    )

    @brand.public_send(asset_name).attach(blob)
  end

  # CloudFront only routes /assets/* requests to the assets bucket, and caches
  # objects until their key changes, so keys must be unique per upload
  def key_for(asset_name, content_type)
    "assets/brands/#{@brand.slug}/#{asset_name.to_s.dasherize}-#{SecureRandom.hex(3)}.#{FILE_EXTENSIONS.fetch(content_type)}"
  end
end
