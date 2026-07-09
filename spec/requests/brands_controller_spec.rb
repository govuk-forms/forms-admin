require "rails_helper"

RSpec.describe BrandsController, type: :request do
  shared_examples "unauthorized user is forbidden" do
    context "when the user is not a super admin" do
      before do
        login_as_standard_user

        get path
      end

      it "returns http code 403 and renders forbidden" do
        expect(response).to have_http_status(:forbidden)
        expect(response).to render_template("errors/forbidden")
      end
    end
  end

  describe "#index" do
    let(:path) { brands_path }

    let!(:brand) { create :brand, slug: "cheshire-east", name: "Cheshire East Council" }
    let!(:other_brand) { create :brand, slug: "south-gloucestershire", name: "South Gloucestershire Council" }

    include_examples "unauthorized user is forbidden"

    context "when the user is a super admin" do
      before do
        login_as_super_admin_user

        get path
      end

      it "returns http code 200 and renders the index view" do
        expect(response).to have_http_status(:ok)
        expect(response).to render_template("brands/index")
      end

      it "lists all brands with their slugs" do
        expect(response.body).to include(brand.name)
        expect(response.body).to include(brand.slug)
        expect(response.body).to include(other_brand.name)
        expect(response.body).to include(other_brand.slug)
      end

      it "links each brand to its show page" do
        page = Capybara.string(response.body)
        expect(page).to have_link(brand.name, href: brand_path(brand))
      end
    end
  end

  describe "#show" do
    let(:brand) { create :brand, slug: "cheshire-east", name: "Cheshire East Council" }
    let(:path) { brand_path(brand) }

    include_examples "unauthorized user is forbidden"

    context "when the user is a super admin" do
      before do
        login_as_super_admin_user

        get path
      end

      it "returns http code 200 and renders the show view" do
        expect(response).to have_http_status(:ok)
        expect(response).to render_template("brands/show")
      end

      it "shows the brand's properties" do
        expect(response.body).to include(brand.name)
        expect(response.body).to include(brand.slug)
      end
    end
  end
end
