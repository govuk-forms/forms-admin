require "rails_helper"

RSpec.describe Forms::BrandController, type: :request do
  let(:form) { create(:form, :live, brand_id: "south-gloucestershire") }
  let(:brand_id) { "cheshire-east" }

  let(:group) { create(:group, organisation: standard_user.organisation, custom_branding_enabled:) }
  let(:custom_branding_enabled) { true }

  before do
    cheshire_east = create(:brand, slug: "cheshire-east", name: "Cheshire East Council")
    south_gloucestershire = create(:brand, slug: "south-gloucestershire", name: "South Gloucestershire Council")
    create(:organisation_brand, organisation: standard_user.organisation, brand: cheshire_east)
    create(:organisation_brand, organisation: standard_user.organisation, brand: south_gloucestershire)

    Membership.create!(group_id: group.id, user: standard_user, added_by: standard_user)
    GroupForm.create!(form_id: form.id, group_id: group.id)

    login_as_standard_user
  end

  describe "#new" do
    it "renders the brand page" do
      get(form_brand_path(form_id: form.id))
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("brand_input.heading"))
    end

    context "when the custom_branding feature is disabled" do
      let(:custom_branding_enabled) { false }

      it "returns 404" do
        get(form_brand_path(form_id: form.id))
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "#create" do
    let(:params) { { forms_brand_input: { brand_id: } } }

    context "when the custom_branding feature is disabled" do
      let(:custom_branding_enabled) { false }

      it "returns 404 and does not update the form" do
        expect {
          post(form_brand_path(form_id: form.id), params:)
        }.not_to(change { form.reload.brand_id })

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when the brand is changed" do
      it "updates the form" do
        expect {
          post(form_brand_path(form_id: form.id), params:)
        }.to change { form.reload.brand_id }.to(brand_id)
      end

      it "redirects you to the form overview page" do
        post(form_brand_path(form_id: form.id), params:)
        expect(response).to redirect_to(form_path(form.id))
      end

      it "displays a flash message that the brand has been saved" do
        post(form_brand_path(form_id: form.id), params:)
        expect(flash[:success]).to eq(I18n.t("banner.success.form.brand_saved"))
      end
    end

    context "when a brand is added" do
      let(:form) { create(:form, :live, brand_id: nil) }

      before do
        post(form_brand_path(form_id: form.id), params:)
      end

      it "displays a flash message that the brand has been saved" do
        expect(flash[:success]).to eq(I18n.t("banner.success.form.brand_saved"))
      end
    end

    context "when the brand is removed" do
      let(:brand_id) { "" }

      it "clears the brand_id on the form" do
        expect {
          post(form_brand_path(form_id: form.id), params:)
        }.to change { form.reload.brand_id }.to(nil)
      end

      it "displays a flash message that the form will use the GOV.UK branding" do
        post(form_brand_path(form_id: form.id), params:)
        expect(flash[:success]).to eq(I18n.t("banner.success.form.brand_removed"))
      end
    end

    context "when the brand is unchanged" do
      let(:form) { create(:form, :live, brand_id:) }

      before do
        post(form_brand_path(form_id: form.id), params:)
      end

      it "does not display a flash message" do
        expect(flash[:success]).to be_nil
      end
    end

    context "when the brand was not previously set and no brand is chosen" do
      let(:form) { create(:form, :live, brand_id: nil) }
      let(:brand_id) { "" }

      before do
        post(form_brand_path(form_id: form.id), params:)
      end

      it "does not display a flash message" do
        expect(flash[:success]).to be_nil
      end
    end

    context "when the brand is not in the configured list" do
      let(:brand_id) { "not-a-brand" }

      it "does not update the form and re-renders the page with an error" do
        expect {
          post(form_brand_path(form_id: form.id), params:)
        }.not_to(change { form.reload.brand_id })

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include(I18n.t("activemodel.errors.models.forms/brand_input.attributes.brand_id.inclusion"))
      end
    end
  end
end
