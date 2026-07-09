class BrandsController < WebController
  after_action :verify_authorized

  def index
    authorize Brand, :can_view_brands?

    @brands = Brand.order(:name)
  end

  def show
    authorize Brand, :can_view_brands?

    @brand = Brand.find(params[:id])
  end
end
