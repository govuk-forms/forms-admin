class BrandsController < WebController
  before_action :set_brand, only: %i[show edit update]
  after_action :verify_authorized

  def index
    authorize Brand, :can_view_brands?

    @brands = Brand.order(:name).load

    # forms reference brands by slug rather than by id
    @organisation_counts = OrganisationBrand.group(:brand_id).count
    @live_form_counts = Form.joins(:latest_form_document)
                            .where(state: %w[live live_with_draft])
                            .group("form_documents.content->>'brand_id'").count
    @draft_form_counts = Form.where(state: %w[draft live_with_draft archived_with_draft]).group(:brand_id).count
  end

  def show
    authorize Brand, :can_view_brands?
  end

  def new
    authorize Brand, :can_edit_brands?

    @brand = Brand.new
  end

  def create
    authorize Brand, :can_edit_brands?

    @brand = Brand.new(brand_params)

    if @brand.save
      BrandAssetsService.new(brand: @brand).attach_assets
      redirect_to @brand, success: t("brands.success_messages.create")
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
    authorize Brand, :can_edit_brands?
  end

  def update
    authorize Brand, :can_edit_brands?

    if @brand.update(brand_params)
      BrandAssetsService.new(brand: @brand).attach_assets
      redirect_to @brand, success: t("brands.success_messages.update"), status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

private

  def set_brand
    @brand = Brand.find(params[:id])
  end

  def brand_params
    params.require(:brand).permit(:name, :header_background_colour, :border_colour, :logo_alt_text, :logo_link, :copyright_holder, :logo_file, :favicon_file, :opengraph_image_file)
  end
end
