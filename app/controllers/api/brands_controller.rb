class Api::BrandsController < ApplicationController
  def show
    expires_in 5.minutes, public: true
    render json: brand.as_json(only: %i[name slug header_background_colour border_colour logo_alt_text logo_link copyright_holder])
  end

private

  def brand
    Brand.find_by!(id: params[:brand_id])
  end
end
