require "rails_helper"

describe "forms/batch_submissions/new.html.erb" do
  let(:form) { create(:form) }
  let(:batch_submissions_input) { Forms::BatchSubmissionsInput.new(form:).assign_form_values }

  before do
    assign(:batch_submissions_input, batch_submissions_input)
    render
  end

  it "sets the page title" do
    expect(view.content_for(:title)).to eq(t("page_titles.submission_batches"))
  end

  it "has the correct heading" do
    expect(rendered).to have_css("h1", text: t("page_titles.submission_batches"))
  end

  it "includes the expected body text" do
    expect(rendered).to include(t("forms.batch_submissions.new.body_html"))
  end

  it "includes the expected fieldset legend" do
    expect(rendered).to have_css("legend", text: "Do you want to get a daily or weekly CSV of submissions to this form?")
  end

  it "has a checkbox for daily submissions batches" do
    expect(rendered).to have_css("input[type='checkbox'][value='daily']")
  end

  it "has a checkbox for weekly submissions batches" do
    expect(rendered).to have_css("input[type='checkbox'][value='weekly']")
  end

  it "includes the expected checkbox label" do
    expect(rendered).to have_css(".govuk-label[for='forms-batch-submissions-input-batch-frequencies-daily-field']", text: "Get a daily CSV of submissions")
  end

  context "when the form has daily batches enabled" do
    let(:form) do
      create(:form, delivery_configurations: [
        create(:delivery_configuration, :daily_email),
      ])
    end

    it "renders the checkbox as checked" do
      expect(rendered).to have_checked_field("forms-batch-submissions-input-batch-frequencies-daily-field")
    end
  end

  context "when the form has weekly batches enabled" do
    let(:form) do
      create(:form, delivery_configurations: [
        create(:delivery_configuration, :weekly_email),
      ])
    end

    it "renders the checkbox as checked" do
      expect(rendered).to have_checked_field("forms-batch-submissions-input-batch-frequencies-weekly-field")
    end
  end

  context "when the form has batch submissions disabled" do
    let(:form) do
      create(:form, delivery_configurations: [
        create(:delivery_configuration, :immediate_email),
      ])
    end

    it "renders the checkboxes as unchecked" do
      expect(rendered).to have_unchecked_field("forms-batch-submissions-input-batch-frequencies-daily-field")
      expect(rendered).to have_unchecked_field("forms-batch-submissions-input-batch-frequencies-weekly-field")
    end
  end
end
