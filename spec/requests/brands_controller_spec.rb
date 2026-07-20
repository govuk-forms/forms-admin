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
    end
  end

  describe "#create" do
    let(:path) { brands_path }
    let(:params) { { brand: { name: "Testshire Council", slug: "testshire" } } }

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

      it "creates a brand with the given name and slug" do
        expect {
          post path, params: params
        }.to change(Brand, :count).by(1)

        brand = Brand.last
        expect(brand.name).to eq("Testshire Council")
        expect(brand.slug).to eq("testshire")
      end

      it "redirects to the brand page with a success message" do
        post path, params: params

        expect(response).to redirect_to(brand_path(Brand.last))
        expect(flash[:success]).to eq(I18n.t("brands.success_messages.create"))
      end

      context "when the brand is invalid" do
        let(:params) { { brand: { name: "", slug: "testshire" } } }

        it "does not create a brand and re-renders the new view" do
          expect {
            post path, params: params
          }.not_to change(Brand, :count)

          expect(response).to have_http_status(:unprocessable_content)
          expect(response).to render_template("brands/new")
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
    end
  end

  describe "#update" do
    let(:brand) { create :brand, slug: "testshire", name: "Testshire Council" }
    let(:path) { brand_path(brand) }
    let(:params) { { brand: { name: "Greater Testshire Council", slug: "greater-testshire" } } }

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

      it "updates the brand's name but not its slug" do
        put path, params: params

        expect(brand.reload).to have_attributes(name: "Greater Testshire Council", slug: "testshire")
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
    end
  end
end
