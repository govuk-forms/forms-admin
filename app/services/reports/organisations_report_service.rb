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

  def users_per_organisation_report
    {
      caption: I18n.t("reports.users_per_organisation.heading"),
      head: [
        { text: I18n.t("reports.users_per_organisation.table_headings.organisation_name") },
        { text: I18n.t("reports.users_per_organisation.table_headings.user_count"), numeric: true },
      ],
      rows: users_per_organisation_rows,
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

  def users_per_organisation_rows
    rows = user_counts_per_organisation.map do |org_name, count|
      [
        { text: org_name || I18n.t("users.index.organisation_blank") },
        { text: count, numeric: true },
      ]
    end

    rows.unshift([
      { text: I18n.t("reports.users_per_organisation.table_headings.total_number_of_users") },
      { text: total_user_count, numeric: true },
    ])
  end

  def user_counts_per_organisation
    User.left_joins(:organisation)
        .group("organisations.id")
        .select("organisations.name, COUNT(users.id) AS user_count")
        .order(Arel.sql("COUNT(users.id) DESC"))
        .order("organisations.name")
        .pluck("organisations.name", "COUNT(users.id)")
  end

  def total_user_count
    User.count
  end
end
