require "rails_helper"

describe "reports/organisation_domains.html.erb" do
  let(:data) do
    {
      caption: "table caption",
      head: [
        { text: "heading" },
      ],
      rows: [
        [{ text: "row 1" }, { text: "value" }],
      ],
    }
  end

  before do
    render template: "reports/organisation_domains", locals: { data: }
  end

  it "has the expected title" do
    expect(view.content_for(:title)).to eq I18n.t("reports.organisation_domains.title")
  end

  it "contains page heading" do
    expect(rendered).to have_css("h1.govuk-heading-l", text: I18n.t("reports.organisation_domains.title"))
  end

  it "has a back link to the reports" do
    expect(view.content_for(:back_link)).to have_link("Back to reports", href: reports_path)
  end

  it "contains the table" do
    expect(rendered).to have_table(with_rows: [["row 1", "value"]])
  end
end
