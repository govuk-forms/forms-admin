require "rails_helper"

RSpec.describe OrganisationBrandsController, type: :request do
  let(:organisation) { create :organisation, slug: "department-for-testing" }
  let(:brand) { create :brand, slug: "cheshire-east", name: "Cheshire East Council" }

  describe "#new" do
    let(:path) { new_organisation_brand_path(organisation) }

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

    context "when the user is a super admin" do
      let!(:added_brand) { create :brand, name: "Already Added Council" }
      let!(:available_brand) { create :brand, name: "Available Council" }

      before do
        create :organisation_brand, organisation:, brand: added_brand

        login_as_super_admin_user

        get path
      end

      it "returns http code 200 and renders the new view" do
        expect(response).to have_http_status(:ok)
        expect(response).to render_template("organisation_brands/new")
      end

      it "includes brands that have not been added to the organisation" do
        expect(response.body).to include(available_brand.name)
      end

      it "does not include brands that have already been added to the organisation" do
        expect(response.body).not_to include(added_brand.name)
      end
    end
  end

  describe "#create" do
    let(:path) { organisation_brands_path(organisation) }
    let(:params) { { organisations_brand_input: { brand_id: brand.id } } }

    context "when the user is not a super admin" do
      before do
        login_as_standard_user

        post(path, params:)
      end

      it "returns http code 403 and renders forbidden" do
        expect(response).to have_http_status(:forbidden)
        expect(response).to render_template("errors/forbidden")
      end

      it "does not add the brand to the organisation" do
        expect(organisation.brands).to be_empty
      end
    end

    context "when the user is a super admin" do
      before do
        login_as_super_admin_user
      end

      it "adds the brand to the organisation" do
        expect {
          post(path, params:)
        }.to change { organisation.brands.count }.by(1)
      end

      it "redirects to the organisation page with a success message" do
        post(path, params:)

        expect(response).to redirect_to(organisation_path(organisation))
        expect(flash[:success]).to eq(I18n.t("organisation_brands.create.success", brand_name: brand.name))
      end

      context "when no brand is selected" do
        let(:params) { { organisations_brand_input: { brand_id: "" } } }

        it "re-renders the page with an error" do
          post(path, params:)

          expect(response).to have_http_status(:unprocessable_content)
          expect(response.body).to include(I18n.t("activemodel.errors.models.organisations/brand_input.attributes.brand_id.blank"))
        end
      end

      context "when the brand does not exist" do
        let(:params) { { organisations_brand_input: { brand_id: "999999" } } }

        it "re-renders the page with an error" do
          post(path, params:)

          expect(response).to have_http_status(:unprocessable_content)
          expect(response.body).to include(I18n.t("activemodel.errors.models.organisations/brand_input.attributes.brand_id.inclusion"))
        end
      end

      context "when the brand has already been added to the organisation" do
        before do
          create :organisation_brand, organisation:, brand:
        end

        it "re-renders the page with an error" do
          expect {
            post(path, params:)
          }.not_to(change { organisation.brands.count })

          expect(response).to have_http_status(:unprocessable_content)
          expect(response.body).to include(I18n.t("activemodel.errors.models.organisations/brand_input.attributes.brand_id.inclusion"))
        end
      end

      context "when the autocomplete text input has been cleared" do
        let(:params) { { organisations_brand_input: { brand_id: brand.id, brand_id_raw: "" } } }

        it "ignores the stale select value and re-renders the page with an error" do
          expect {
            post(path, params:)
          }.not_to(change { organisation.brands.count })

          expect(response).to have_http_status(:unprocessable_content)
          expect(response.body).to include(I18n.t("activemodel.errors.models.organisations/brand_input.attributes.brand_id.blank"))
        end
      end
    end
  end

  describe "#destroy" do
    let(:path) { organisation_brand_path(organisation, brand) }

    before do
      create :organisation_brand, organisation:, brand:
    end

    context "when the user is not a super admin" do
      before do
        login_as_standard_user

        delete path
      end

      it "returns http code 403 and renders forbidden" do
        expect(response).to have_http_status(:forbidden)
        expect(response).to render_template("errors/forbidden")
      end

      it "does not remove the brand from the organisation" do
        expect(organisation.brands).to include(brand)
      end
    end

    context "when the user is a super admin" do
      before do
        login_as_super_admin_user
      end

      it "removes the brand from the organisation without deleting the brand" do
        expect {
          delete path
        }.to change { organisation.brands.count }.by(-1)

        expect(Brand.exists?(brand.id)).to be true
      end

      it "redirects to the organisation page with a success message" do
        delete path

        expect(response).to redirect_to(organisation_path(organisation))
        expect(flash[:success]).to eq(I18n.t("organisation_brands.destroy.success", brand_name: brand.name))
      end

      context "when the brand is not one of the organisation's brands" do
        let(:other_brand) { create :brand }
        let(:path) { organisation_brand_path(organisation, other_brand) }

        it "returns http code 404" do
          delete path

          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end
end
