require "rails_helper"

describe "mou_signatures/index.html.erb" do
  let(:mou_signatures) do
    [
      build(:mou_signature, user: build_stubbed(:user), agreement_type: :crown, created_at: Time.zone.parse("October 12, 2023")),
      build(:mou_signature, user: build_stubbed(:user), agreement_type: :non_crown, created_at: Time.zone.parse("October 13, 2023")),
    ]
  end

  before do
    render template: "mou_signatures/index", locals: { mou_signatures: }
  end

  it "contains page heading" do
    expect(rendered).to have_css("h1.govuk-heading-l", text: I18n.t("page_titles.mou_signatures"))
  end

  it "contains a scrollable wrapper with a table in it" do
    expect(rendered).to have_css(".app-scrolling-wrapper > table")
  end

  it "contains the agreement type" do
    expect(rendered).to have_xpath "//thead/tr/th[1]", text: I18n.t("mou_signatures.index.table_headings.agreement_type")
    expect(rendered).to have_xpath "//tbody/tr[1]/td[1]", text: I18n.t("mou_signatures.index.agreement_type.crown")
    expect(rendered).to have_xpath "//tbody/tr[2]/td[1]", text: I18n.t("mou_signatures.index.agreement_type.non_crown")
  end

  it "contains the user's name" do
    expect(rendered).to have_text(mou_signatures.first.user.name)
  end

  it "contains the user's email as a link to the edit page" do
    expect(rendered).to have_link(mou_signatures.first.user.email, href: edit_user_path(mou_signatures.first.user))
  end

  it "contains organisation name" do
    expect(rendered).to have_text(mou_signatures.first.user.organisation.name)
  end

  it "contains the date the MOU was signed" do
    expect(rendered).to have_text(I18n.l(mou_signatures.first.created_at.to_date, format: :long))
  end

  context "when there are no signed MOUs" do
    let(:mou_signatures) { [] }

    it "does not show the MOU table" do
      expect(rendered).not_to have_text(I18n.t("mou_signatures.table_caption"))
      expect(rendered).not_to have_css("table")
    end
  end
end
