require "rails_helper"

RSpec.describe OrganisationsController, type: :request do
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
    let(:path) { organisations_path }

    let!(:organisation) { create :organisation, slug: "department-for-testing" }
    let!(:closed_organisation) { create :organisation, slug: "closed-department", closed: true }

    let(:group) { create :group, organisation: }

    include_examples "unauthorized user is forbidden"

    context "when the user is a super admin" do
      before do
        create(:form, :live, :with_group, group:)
        create_list(:form, 2, :with_group, group:)
        create(:form, :archived, :with_group, group:)

        login_as_super_admin_user

        get path
      end

      it "returns http code 200 and renders the index view" do
        expect(response).to have_http_status(:ok)
        expect(response).to render_template("organisations/index")
      end

      it "lists all organisations, including closed ones" do
        expect(response.body).to include(organisation.name)
        expect(response.body).to include(closed_organisation.name)
      end

      it "shows the number of live forms in each organisation, not counting archived forms" do
        page = Capybara.string(response.body)
        expect(page).to have_xpath "//tbody/tr[2]/td[3]", text: "1"
        expect(page).to have_xpath "//tbody/tr[1]/td[3]", text: "0"
      end

      it "shows the number of draft forms in each organisation, not counting archived forms" do
        page = Capybara.string(response.body)
        expect(page).to have_xpath "//tbody/tr[2]/td[4]", text: "2"
        expect(page).to have_xpath "//tbody/tr[1]/td[4]", text: "0"
      end
    end

    context "when filtering" do
      let!(:organisation_with_crown_mou) { create :organisation, :with_signed_mou, slug: "department-with-mou" }
      let!(:organisation_with_non_crown_agreement) { create :organisation, slug: "department-with-non-crown-agreement" }

      before do
        create :mou_signature_for_organisation, organisation: organisation_with_non_crown_agreement, agreement_type: :non_crown

        login_as_super_admin_user
      end

      it "filters organisations by name" do
        get path, params: { filter: { name: "closed" } }

        expect(response.body).to include(closed_organisation.name)
        expect(response.body).not_to include(organisation.name)
      end

      it "filters organisations with a Crown MOU" do
        get path, params: { filter: { agreement_type: "crown" } }

        expect(response.body).to include(organisation_with_crown_mou.name)
        expect(response.body).not_to include(organisation_with_non_crown_agreement.name)
        expect(response.body).not_to include(closed_organisation.name)
      end

      it "filters organisations with a non-crown agreement" do
        get path, params: { filter: { agreement_type: "non_crown" } }

        expect(response.body).to include(organisation_with_non_crown_agreement.name)
        expect(response.body).not_to include(organisation_with_crown_mou.name)
        expect(response.body).not_to include(closed_organisation.name)
      end

      it "filters organisations without a signed agreement" do
        get path, params: { filter: { agreement_type: "none" } }

        expect(response.body).to include(closed_organisation.name)
        expect(response.body).not_to include(organisation_with_crown_mou.name)
        expect(response.body).not_to include(organisation_with_non_crown_agreement.name)
      end
    end

    context "when sorting" do
      let!(:organisation_a) { create :organisation, name: "Alpha department", slug: "alpha-department" }
      let!(:organisation_n) { create :organisation, name: "November department", slug: "november-department" }
      let!(:organisation_z) { create :organisation, name: "Zulu department", slug: "zulu-department", closed: true }

      def organisation_row_order(response)
        page = Capybara.string(response.body)
        page.all("tbody tr td:first-child").map(&:text).map(&:strip)
      end

      before do
        login_as_super_admin_user

        create_list :user, 3, organisation: organisation_z
        create :user, organisation: organisation_a

        group = create :group, organisation: organisation_n
        create :form, :with_group, group:
      end

      it "sorts by name ascending by default" do
        get path

        expect(organisation_row_order(response).first).to eq(organisation_a.name_with_abbreviation)
      end

      it "sorts by user count descending" do
        get path, params: { filter: { sort: "users" } }

        expect(organisation_row_order(response).first).to eq(organisation_z.name_with_abbreviation)
      end

      it "sorts by live form count descending" do
        group = create :group, organisation: organisation_z
        create(:form, :live, :with_group, group:)

        get path, params: { filter: { sort: "live_forms" } }

        expect(organisation_row_order(response).first).to eq(organisation_z.name_with_abbreviation)
      end

      it "sorts by draft form count descending" do
        get path, params: { filter: { sort: "draft_forms" } }

        expect(organisation_row_order(response).first).to eq(organisation_n.name_with_abbreviation)
      end

      it "sorts by first agreement signed date descending, organisations without an agreement last" do
        create :mou_signature_for_organisation, organisation: organisation_n, created_at: 1.year.ago
        create :mou_signature_for_organisation, organisation: organisation_z, created_at: 1.week.ago

        get path, params: { filter: { sort: "agreement_date" } }

        rows = organisation_row_order(response)
        expect(rows.index(organisation_z.name_with_abbreviation)).to be < rows.index(organisation_n.name_with_abbreviation)
        expect(rows.index(organisation_n.name_with_abbreviation)).to be < rows.index(organisation_a.name_with_abbreviation)
      end

      it "falls back to name for an unknown sort option" do
        get path, params: { filter: { sort: "malicious" } }

        expect(organisation_row_order(response).first).to eq(organisation_a.name_with_abbreviation)
      end

      it "sorts while filtering by agreement type at the same time" do
        organisation_with_mou = create :organisation, :with_signed_mou, name: "Mike department", slug: "mike-department"

        get path, params: { filter: { agreement_type: "crown", sort: "users" } }

        expect(response).to have_http_status(:ok)
        expect(organisation_row_order(response)).to include(organisation_with_mou.name_with_abbreviation)
        expect(organisation_row_order(response)).not_to include(organisation_a.name_with_abbreviation, organisation_n.name_with_abbreviation, organisation_z.name_with_abbreviation)
      end
    end
  end

  describe "#show" do
    let(:organisation) { create :organisation, :with_org_admin, slug: "department-for-testing" }
    let(:path) { organisation_path(organisation) }

    let!(:organisation_domain) { create :organisation_domain, organisation: }
    let!(:organisation_brand) { create :organisation_brand, organisation: }

    include_examples "unauthorized user is forbidden"

    context "when the user is a super admin" do
      before do
        login_as_super_admin_user

        get path
      end

      it "returns http code 200 and renders the show view" do
        expect(response).to have_http_status(:ok)
        expect(response).to render_template("organisations/show")
      end

      it "shows the organisation's configuration" do
        expect(response.body).to include(organisation.name)
        expect(response.body).to include(organisation.slug)
        expect(response.body).to include(organisation.admin_users.first.email)
        expect(response.body).to include(I18n.t("mou_signatures.index.agreement_type.#{organisation.mou_signatures.first.agreement_type}"))
        expect(response.body).to include(organisation_domain.domain)
      end

      it "shows the organisation's brands with a link to add a brand" do
        expect(response.body).to include(organisation_brand.brand.name)
        expect(response.body).to include(I18n.t("organisations.show.brands.guidance"))
        expect(response.body).to include(I18n.t("organisations.show.brands.add"))
        expect(response.body).to include(new_organisation_brand_path(organisation))
      end
    end
  end
end
