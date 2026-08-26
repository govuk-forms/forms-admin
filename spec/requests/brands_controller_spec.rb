require "rails_helper"

RSpec.describe BrandsController, type: :request do
  shared_examples "unauthorized user is forbidden" do
    let(:do_request) { get path }

    context "when the user is not a super admin" do
      before do
        login_as_standard_user

        do_request
      end

      it "returns http code 403 and renders forbidden" do
        expect(response).to have_http_status(:forbidden)
        expect(response).to render_template("errors/forbidden")
      end
    end
  end

  describe "#index" do
    let(:path) { brands_path }

    let!(:brand) { create :brand, slug: "testshire", name: "Testshire Council" }
    let!(:other_brand) { create :brand, slug: "exampleton", name: "Exampleton Town Council" }

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
    let(:brand) { create :brand, slug: "testshire", name: "Testshire Council" }
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
        expect(response.body).to include(brand.logo_alt_text)
        expect(response.body).to include(brand.logo_link)
        expect(response.body).to include(brand.header_background_colour)
        expect(response.body).to include(brand.border_colour)
        expect(response.body).to include(brand.copyright_holder)
      end

      it "shows that no assets have been uploaded" do
        expect(response.body).to include(I18n.t("brands.show.summary.not_uploaded"))
      end
    end

    context "when the user is a super admin and the brand has assets" do
      before do
        brand.logo_file = fixture_file_upload("logo.png", "image/png")
        BrandAssetsService.new(brand:).attach_assets

        login_as_super_admin_user

        get path
      end

      it "links to the public path of each uploaded asset" do
        page = Capybara.string(response.body)
        expect(page).to have_link("/#{brand.logo.blob.key}", href: "/#{brand.logo.blob.key}")
      end
    end
  end

  describe "#new" do
    let(:path) { new_brand_path }

    include_examples "unauthorized user is forbidden"

    context "when the user is a super admin" do
      before do
        login_as_super_admin_user

        get path
      end

      it "returns http code 200 and renders the new view" do
        expect(response).to have_http_status(:ok)
        expect(response).to render_template("brands/new")
      end

      it "has a labelled field for each brand attribute" do
        page = Capybara.string(response.body)
        ["Brand name", "Slug", "Logo alt text", "Logo link", "Header background colour", "Header and footer border colour", "Copyright holder", "Logo", "Favicon", "Opengraph image"].each do |label|
          expect(page).to have_field(label)
        end
      end

      it "renders a multipart form so that files can be uploaded" do
        page = Capybara.string(response.body)
        expect(page).to have_css("form[enctype='multipart/form-data']")
      end
    end
  end

  describe "#create" do
    let(:path) { brands_path }
    let(:params) do
      {
        brand: {
          name: "Testshire Council",
          slug: "testshire",
          header_background_colour: "#ffffff",
          border_colour: "#206c49",
          logo_alt_text: "Testshire Council",
          logo_link: "https://www.testshire.example.com",
          copyright_holder: "Testshire Council",
        },
      }
    end

    it_behaves_like "unauthorized user is forbidden" do
      let(:do_request) { post path, params: params }
    end

    context "when the user is not a super admin" do
      before do
        login_as_standard_user
      end

      it "does not create a brand" do
        expect {
          post path, params: params
        }.not_to change(Brand, :count)
      end
    end

    context "when the user is a super admin" do
      before do
        login_as_super_admin_user
      end

      it "creates a brand with the given attributes" do
        expect {
          post path, params: params
        }.to change(Brand, :count).by(1)

        brand = Brand.last
        expect(brand).to have_attributes(
          name: "Testshire Council",
          slug: "testshire",
          header_background_colour: "#ffffff",
          border_colour: "#206c49",
          logo_alt_text: "Testshire Council",
          logo_link: "https://www.testshire.example.com",
          copyright_holder: "Testshire Council",
        )
      end

      it "redirects to the brand page with a success message" do
        post path, params: params

        expect(response).to redirect_to(brand_path(Brand.last))
        expect(flash[:success]).to eq(I18n.t("brands.success_messages.create"))
      end

      context "when the brand is invalid" do
        before do
          params[:brand][:name] = ""
        end

        it "does not create a brand and re-renders the new view" do
          expect {
            post path, params: params
          }.not_to change(Brand, :count)

          expect(response).to have_http_status(:unprocessable_content)
          expect(response).to render_template("brands/new")
        end
      end

      context "when a colour is not a hex colour code" do
        before do
          params[:brand][:border_colour] = "green"
        end

        it "does not create a brand and re-renders the new view" do
          expect {
            post path, params: params
          }.not_to change(Brand, :count)

          expect(response).to have_http_status(:unprocessable_content)
          expect(response).to render_template("brands/new")
        end
      end

      context "when asset files are uploaded" do
        before do
          params[:brand][:logo_file] = fixture_file_upload("logo.png", "image/png")
          params[:brand][:favicon_file] = fixture_file_upload("favicon.ico", "image/vnd.microsoft.icon")
          params[:brand][:opengraph_image_file] = fixture_file_upload("logo.jpeg", "image/jpeg")
        end

        it "creates the brand with the assets attached under public asset keys" do
          expect {
            post path, params: params
          }.to change(Brand, :count).by(1)

          brand = Brand.last
          expect(brand.logo.blob.key).to match(%r{\Aassets/brands/testshire/logo-\h{6}\.png\z})
          expect(brand.favicon.blob.key).to match(%r{\Aassets/brands/testshire/favicon-\h{6}\.ico\z})
          expect(brand.opengraph_image.blob.key).to match(%r{\Aassets/brands/testshire/opengraph-image-\h{6}\.jpg\z})
        end
      end

      context "when an asset file has a disallowed file type" do
        before do
          params[:brand][:logo_file] = fixture_file_upload("invalid.txt", "text/plain")
        end

        it "does not create a brand and re-renders the new view with an error" do
          expect {
            post path, params: params
          }.not_to change(Brand, :count)

          expect(response).to have_http_status(:unprocessable_content)
          expect(response).to render_template("brands/new")
          expect(response.body).to include(I18n.t("activerecord.errors.models.brand.attributes.logo_file.invalid_file_type"))
        end
      end
    end
  end

  describe "#edit" do
    let(:brand) { create :brand, slug: "testshire", name: "Testshire Council" }
    let(:path) { edit_brand_path(brand) }

    include_examples "unauthorized user is forbidden"

    context "when the user is a super admin" do
      before do
        login_as_super_admin_user

        get path
      end

      it "returns http code 200 and renders the edit view" do
        expect(response).to have_http_status(:ok)
        expect(response).to render_template("brands/edit")
      end

      it "has a labelled field for each editable brand attribute" do
        page = Capybara.string(response.body)
        ["Brand name", "Logo alt text", "Logo link", "Header background colour", "Header and footer border colour", "Copyright holder"].each do |label|
          expect(page).to have_field(label)
        end
      end
    end
  end

  describe "#update" do
    let(:brand) { create :brand, slug: "testshire", name: "Testshire Council" }
    let(:path) { brand_path(brand) }
    let(:params) do
      {
        brand: {
          name: "Greater Testshire Council",
          slug: "greater-testshire",
          header_background_colour: "#f0f0f0",
          border_colour: "#123abc",
          logo_alt_text: "Greater Testshire Council",
          logo_link: "https://www.greater-testshire.example.com",
          copyright_holder: "Greater Testshire Council",
        },
      }
    end

    it_behaves_like "unauthorized user is forbidden" do
      let(:do_request) { put path, params: params }
    end

    context "when the user is not a super admin" do
      before do
        login_as_standard_user
      end

      it "does not change the brand" do
        expect {
          put path, params: params
        }.not_to(change { brand.reload.attributes })
      end
    end

    context "when the user is a super admin" do
      before do
        login_as_super_admin_user
      end

      it "updates the brand's attributes but not its slug" do
        put path, params: params

        expect(brand.reload).to have_attributes(
          name: "Greater Testshire Council",
          slug: "testshire",
          header_background_colour: "#f0f0f0",
          border_colour: "#123abc",
          logo_alt_text: "Greater Testshire Council",
          logo_link: "https://www.greater-testshire.example.com",
          copyright_holder: "Greater Testshire Council",
        )
      end

      it "redirects to the brand page with a success message" do
        put path, params: params

        expect(response).to redirect_to(brand_path(brand))
        expect(flash[:success]).to eq(I18n.t("brands.success_messages.update"))
      end

      context "when the brand is invalid" do
        let(:params) { { brand: { name: "" } } }

        it "does not change the brand and re-renders the edit view" do
          expect {
            put path, params: params
          }.not_to(change { brand.reload.attributes })

          expect(response).to have_http_status(:unprocessable_content)
          expect(response).to render_template("brands/edit")
        end
      end

      context "when the brand already has assets" do
        before do
          brand.logo_file = fixture_file_upload("logo.png", "image/png")
          brand.favicon_file = fixture_file_upload("favicon.ico", "image/vnd.microsoft.icon")
          BrandAssetsService.new(brand:).attach_assets
        end

        it "replaces an asset when a new file is uploaded" do
          original_key = brand.logo.blob.key

          params[:brand][:logo_file] = fixture_file_upload("logo.jpeg", "image/jpeg")
          put path, params: params

          expect(brand.reload.logo.blob.key).to match(%r{\Aassets/brands/testshire/logo-\h{6}\.jpg\z})
          expect(brand.logo.blob.key).not_to eq original_key
        end

        it "keeps the existing assets when no files are uploaded" do
          expect {
            put path, params: params
          }.not_to(change { [brand.reload.logo.blob.key, brand.favicon.blob.key] })
        end
      end
    end
  end
end
