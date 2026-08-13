class Reports::OrganisationsReportService
  def organisation_domains_report
    {
      caption: I18n.t("reports.organisation_domains.heading"),
      head: [
        { text: I18n.t("reports.organisation_domains.table_headings.organisation") },
        { text: I18n.t("reports.organisation_domains.table_headings.slug") },
        { text: I18n.t("reports.organisation_domains.table_headings.domains") },
      ],
      rows: organisation_domains_rows,
      first_cell_is_header: true,
    }
  end

private

  def organisation_domains_rows
    organisation_domains_data.map do |organisation_name, organisation_slug, domains|
      [{ text: organisation_name }, { text: organisation_slug }, { text: domains.html_safe }]
    end
  end

  def organisation_domains_data
    Organisation.includes(:organisation_domains).order(:name).map do |organisation|
      domains = organisation.organisation_domains.pluck(:domain).sort
      domains_list = domains.any? ? ActionController::Base.helpers.govuk_list(domains, type: :bullet) : ""
      [organisation.name, organisation.slug, domains_list]
    end
  end
end
