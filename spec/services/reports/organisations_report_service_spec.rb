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
end
