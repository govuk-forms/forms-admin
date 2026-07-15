require "rails_helper"

RSpec.describe Api::BrandsController, type: :request do
  let(:headers) { { "ACCEPT": "application/json" } }

  describe "#show" do
    context "when the brand exists" do
      let(:brand) { create :brand, name: "Golden Zephyr", slug: "golden-zephyr" }

      before do
        get "/api/v2/brands/#{brand.id}", headers:
      end

      it "returns http success" do
        expect(response).to have_http_status(:success)
      end

      it "returns the brand configuration" do
        expect(response.parsed_body).to eq({
          "name" => "Golden Zephyr",
          "slug" => "golden-zephyr",
        })
      end

      it "sets the response to be cached for 5 minutes" do
        expect(response.headers["Cache-Control"]).to eq("max-age=300, public")
      end
    end

    context "when the brand does not exist" do
      before do
        get "/api/v2/brands/0", headers:
      end

      it "returns http not found" do
        expect(response).to have_http_status(:not_found)
        expect(response.headers["Content-Type"]).to eq("application/json; charset=utf-8")
      end
    end
  end
end
