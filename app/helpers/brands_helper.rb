module BrandsHelper
  def brand_asset_path(attachment)
    "/#{attachment.blob.key}" if attachment.attached?
  end
end
