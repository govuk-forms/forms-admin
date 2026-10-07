require "rails_helper"

RSpec.describe "organisation_feature_flags/edit", type: :view do
  # No feature is organisation-scoped yet, so use an existing boolean column as a stand-in flag
  let(:feature_flag) { "internal" }
  let(:other_feature_flag) { "closed" }

  let(:organisation) { create :organisation, feature_flag => false, other_feature_flag => false }
  let(:feature_flags_input) { FeatureFlagsInput.new(record: organisation) }

  before do
    allow(Organisation).to receive(:feature_flag_attributes).and_return([feature_flag, other_feature_flag])
    I18n.backend.store_translations(:en, organisations: { feature_flags: { flags: { feature_flag => "Stand-in flag", other_feature_flag => "Other stand-in flag" } } })

    assign(:organisation, organisation)
    assign(:feature_flags_input, feature_flags_input)
    render
  end

  it "contains the page heading" do
    expect(rendered).to have_css("h1", text: I18n.t("organisation_feature_flags.edit.title"))
  end

  it "renders the feature flags form posting to the update action" do
    assert_select "form[action=?][method=?]", organisation_feature_flags_path(organisation), "post" do
      assert_select "input[name=?]", "feature_flags_input[#{feature_flag}]"
    end
  end

  it "includes a checkbox for each toggleable feature flag" do
    expect(rendered).to have_field("Stand-in flag")
    expect(rendered).to have_field("Other stand-in flag")
  end

  it "includes the organisation name as a caption" do
    expect(rendered).to have_css(".govuk-caption-l", text: organisation.name)
  end

  it "explains that flags cannot be turned off" do
    expect(rendered).to have_text(I18n.t("organisation_feature_flags.edit.hint"))
  end

  context "when a feature flag is already enabled" do
    let(:organisation) { create :organisation, feature_flag => true, other_feature_flag => false }

    it "renders the flag as checked and disabled so it cannot be turned off" do
      assert_select "input[type=checkbox][name=?][checked=checked][disabled=disabled]", "feature_flags_input[#{feature_flag}]"
    end

    it "leaves flags that are off enabled and unchecked" do
      assert_select "input[type=checkbox][name=?]:not([disabled])", "feature_flags_input[#{other_feature_flag}]"
    end
  end

  context "when the form is rendered again after a submission that could not be saved" do
    let(:feature_flags_input) do
      # The disabled checkbox for the enabled flag is not submitted, so only its hidden "false" value arrives
      FeatureFlagsInput.new(record: organisation, submitted: { feature_flag => "true", other_feature_flag => "false" }).tap do |input|
        allow(organisation).to receive(:save).and_return(false)
        input.submit
      end
    end

    it "keeps the submitted flag checked without locking it" do
      assert_select "input[type=checkbox][name=?][checked=checked]:not([disabled])", "feature_flags_input[#{feature_flag}]"
    end

    it "leaves flags that were not ticked unchecked" do
      assert_select "input[type=checkbox][name=?]:not([checked])", "feature_flags_input[#{other_feature_flag}]"
    end
  end
end
