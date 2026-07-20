require "rails_helper"

describe "reports/users_per_organisation.html.erb" do
  let(:data) do
    {
      caption: "table caption",
      head: [
        { text: "org name" },
        { text: "user count", numeric: true },
      ],
      rows: [
        [{ text: "org 1" }, { text: 2, numeric: true }],
        [{ text: "org 2" }, { text: 1, numeric: true }],
      ],
    }
  end

  before do
    render template: "reports/users_per_organisation", locals: { data: }
  end

  describe "page title" do
    it "matches the heading" do
      expect(view.content_for(:title)).to eq "Number of users per organisation"
    end
  end

  it "has a back link to the live form page" do
    expect(view.content_for(:back_link)).to have_link("Back to reports", href: reports_path)
  end

  it "contains page heading" do
    expect(rendered).to have_css("h1.govuk-heading-l", text: "Number of users per organisation")
  end

  it "contains the table" do
    expect(rendered).to have_table(with_rows: [["org 1", "2"], ["org 2", "1"]])
  end
end
