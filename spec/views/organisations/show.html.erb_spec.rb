require "rails_helper"

describe "organisations/show.html.erb" do
  let(:organisation) { create :organisation, :with_org_admin, slug: "department-for-testing" }
  let(:organisation_domains) { [create(:organisation_domain, organisation:, domain: "testing.gov.uk")] }

  before do
    organisation_domains
    group = create(:group, organisation:)
    create(:form, :live, :with_group, group:)
    create_list(:form, 2, :with_group, group:)
    create(:form, :archived, :with_group, group:)

    assign(:organisation, organisation)

    render template: "organisations/show"
  end

  it "contains page heading" do
    expect(rendered).to have_css("h1.govuk-heading-l", text: organisation.name_with_abbreviation)
  end

  it "contains a summary of the organisation's details" do
    expect(rendered).to have_css(".govuk-summary-list__key", text: I18n.t("organisations.show.summary.slug"))
    expect(rendered).to have_css(".govuk-summary-list__value", text: organisation.slug)
  end

  it "shows the live and draft form counts between the user and group counts" do
    users_index = rendered.index(I18n.t("organisations.show.summary.users"))
    live_forms_index = rendered.index(I18n.t("organisations.show.summary.live_forms"))
    draft_forms_index = rendered.index(I18n.t("organisations.show.summary.draft_forms"))
    groups_index = rendered.index(I18n.t("organisations.show.summary.groups"))

    expect(live_forms_index).to be_between(users_index, draft_forms_index)
    expect(draft_forms_index).to be_between(live_forms_index, groups_index)
  end

  it "shows the number of live and draft forms, not counting archived forms" do
    expect(rendered).to have_css(".govuk-summary-list__row", text: /#{I18n.t('organisations.show.summary.live_forms')}\s*1/)
    expect(rendered).to have_css(".govuk-summary-list__row", text: /#{I18n.t('organisations.show.summary.draft_forms')}\s*2/)
  end

  it "shows whether the organisation is internal or closed" do
    expect(rendered).to have_css(".govuk-summary-list__key", text: I18n.t("organisations.show.summary.internal"))
    expect(rendered).to have_css(".govuk-summary-list__key", text: I18n.t("organisations.show.summary.closed"))
  end

  it "lists the organisation admins with links to their edit pages" do
    admin_user = organisation.admin_users.first
    expect(rendered).to have_link(admin_user.email, href: edit_user_path(admin_user))
  end

  it "lists the MOU signatures" do
    mou_signature = organisation.mou_signatures.first
    expect(rendered).to have_text(I18n.t("mou_signatures.index.agreement_type.#{mou_signature.agreement_type}"))
    expect(rendered).to have_link(mou_signature.user.email, href: edit_user_path(mou_signature.user))
    expect(rendered).to have_text(I18n.l(mou_signature.created_at.to_date, format: :long))
  end

  it "lists the organisation's email domains" do
    expect(rendered).to have_text("testing.gov.uk")
  end

  it "does not show the MOU guidance" do
    expect(rendered).not_to have_text("Someone from each organisation needs to agree")
  end

  context "when the organisation has no admins, MOU signatures or domains" do
    let(:organisation) { create :organisation, slug: "empty-department" }
    let(:organisation_domains) { [] }

    it "shows a message for each empty section" do
      expect(rendered).to have_text(I18n.t("organisations.show.admin_users.none"))
      expect(rendered).to have_text(I18n.t("organisations.show.mou_signatures.none"))
      expect(rendered).to have_text(I18n.t("organisations.show.domains.none"))
      expect(rendered).to have_text(I18n.t("organisations.show.brands.none"))
    end

    it "shows brands guidance when there are no brands" do
      expect(rendered).to have_text(I18n.t("organisations.show.brands.guidance"))
    end

    it "shows the MOU guidance with links to the agreements" do
      expect(rendered).to have_text("Someone from each organisation needs to agree")
      expect(rendered).to have_link(mou_signature_url, href: mou_signature_url)
      expect(rendered).to have_link(non_crown_agreement_signature_url, href: non_crown_agreement_signature_url)
    end

    it "shows a fallback for the blank GOV.UK content ID" do
      expect(rendered).to have_css(".govuk-summary-list__value", text: I18n.t("organisations.show.not_set"))
    end
  end
end
