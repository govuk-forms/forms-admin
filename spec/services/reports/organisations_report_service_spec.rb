require "rails_helper"

describe Reports::OrganisationsReportService do
  subject(:service) { described_class.new }

  describe "#organisation_domains_report" do
    it "returns the correct format" do
      expect(service.organisation_domains_report).to match({
        caption: I18n.t("reports.organisation_domains.heading"),
        head: [
          { text: I18n.t("reports.organisation_domains.table_headings.organisation") },
          { text: I18n.t("reports.organisation_domains.table_headings.slug") },
          { text: I18n.t("reports.organisation_domains.table_headings.domains") },
        ],
        rows: [],
        first_cell_is_header: true,
      })
    end

    context "with organisations" do
      it "returns the correct rows" do
        create(:organisation, name: "Test Org", slug: "test-org")
        ministry_org = create(:organisation, name: "Ministry of tests", slug: "ministry-of-tests")
        create(:organisation_domain, domain: "ministry-of-tests.gov.uk", organisation: ministry_org)
        create(:organisation_domain, domain: "mot.gov.uk", organisation: ministry_org)
        juggling_org = create(:organisation, name: "Department of juggling", slug: "department-of-juggling")
        create(:organisation_domain, domain: "juggling.gov.uk", organisation: juggling_org)

        expect(service.organisation_domains_report[:rows]).to contain_exactly(
          [{ text: "Test Org" }, { text: "test-org" }, { text: "" }],
          [{ text: "Ministry of tests" }, { text: "ministry-of-tests" }, { text: '<ul class="govuk-list govuk-list--bullet"><li>ministry-of-tests.gov.uk</li><li>mot.gov.uk</li></ul>' }],
          [{ text: "Department of juggling" }, { text: "department-of-juggling" }, { text: '<ul class="govuk-list govuk-list--bullet"><li>juggling.gov.uk</li></ul>' }],
        )
      end
    end
  end

  describe "#users_per_organisation_report" do
    it "returns the correct format" do
      expect(service.users_per_organisation_report).to match({
        caption: I18n.t("reports.users_per_organisation.heading"),
        first_cell_is_header: true,
        head: [
          { text: I18n.t("reports.users_per_organisation.table_headings.organisation_name") },
          { text: I18n.t("reports.users_per_organisation.table_headings.user_count"), numeric: true },
        ],
        rows: [[{ text: I18n.t("reports.users_per_organisation.table_headings.total_number_of_users") }, { text: 0, numeric: true }]],
      })
    end

    context "with orgs and users" do
      it "returns the correct rows" do
        org1 = create :organisation, slug: "with-most-users"
        org2 = create :organisation, slug: "with-one-user"
        create :organisation, slug: "with-no-users"
        create :user, organisation: org1
        create :user, organisation: org1
        create :user, organisation: org2
        create :user, :with_no_org
        expect(service.users_per_organisation_report[:rows]).to eq([
          [{ text: I18n.t("reports.users_per_organisation.table_headings.total_number_of_users") }, { text: 4, numeric: true }],
          [{ text: org1.name }, { text: 2, numeric: true }],
          [{ text: org2.name }, { text: 1, numeric: true }],
          [{ text: I18n.t("users.index.organisation_blank") }, { text: 1, numeric: true }],
        ])
      end
    end
  end
end
