require "rails_helper"

describe "users/edit.html.erb" do
  let(:organisation) { create :organisation, slug: "test-org" }
  let(:user) do
    build(
      :user,
      id: 1,
      organisation:,
      created_at: Time.zone.local(2023, 10, 16, 13, 24),
      last_signed_in_at: Time.zone.now,
    )
  end

  before do
    create :organisation, slug: "ministry-of-testing"
    create :organisation, slug: "department-for-tests", name: "Department for Tests", abbreviation: "DfT"

    travel_to(Time.zone.local(2024, 8, 26, 11, 50)) do
      assign(:user, user)

      render template: "users/edit"
    end
  end

  describe "page title" do
    it "is the user's name" do
      expect(view.content_for(:title)).to eq user.name
    end

    context "with a user with no name set" do
      let(:user) { build(:user, :with_no_name, id: 1) }

      it "is the users's email address" do
        expect(view.content_for(:title)).to eq user.email
      end
    end

    context "with a user with a blank name" do
      let(:user) { build(:user, name: "", id: 1) }

      it "is the users's email address" do
        expect(view.content_for(:title)).to eq user.email
      end
    end
  end

  it "contains page heading" do
    expect(rendered).to have_css("h1.govuk-heading-l", text: /Edit user/)
  end

  describe "summary list" do
    let(:summary_list) do
      Capybara.string(rendered.html).find(".govuk-summary-list")
    end

    it "contains name" do
      expect(summary_list).to have_text(user.name)
    end

    it "contains email" do
      expect(summary_list).to have_text(user.email)
    end

    context "with user from GOV.UK Signon" do
      let(:user) do
        build :user, :with_unknown_org, id: 1, organisation_slug: "department-for-testing"
      end

      it "contains organisation slug from GOV.UK Signon" do
        expect(summary_list).to have_text(user.organisation_slug)
      end
    end

    it "contains organisation name" do
      expect(rendered).to have_text(user.organisation.name)
    end

    it "contains role" do
      expect(summary_list).to have_text("Standard")
    end

    it "contains first signed in at" do
      expect(summary_list).to have_css(".govuk-summary-list__row") do |row|
        row.has_selector?(".govuk-summary-list__key", text: "First signed in") &&
          row.has_selector?(".govuk-summary-list__value", text: "16 October 2023")
      end
    end

    it "contains last signed in at" do
      expect(summary_list).to have_css(".govuk-summary-list__row") do |row|
        row.has_selector?(".govuk-summary-list__key", text: "Last signed in") &&
          row.has_selector?(".govuk-summary-list__value", text: "26 August 2024")
      end
    end

    it "contains access" do
      expect(summary_list).to have_text("Permitted")
    end
  end

  describe "form" do
    it "has role fields" do
      expect(rendered).to have_checked_field("Standard user")
      expect(rendered).to have_unchecked_field("Super admin")
      expect(rendered).to have_unchecked_field("Organisation admin")
    end

    it "has a name field" do
      expect(rendered).to have_field("Name") do |field|
        expect(field[:autocomplete]).to eq "name"
        expect(field[:spellcheck]).to eq "false"
      end
    end

    it "has organisation fields with abbreviations" do
      expect(rendered).to have_select(
        "Organisation",
        selected: "Test Org (TO)",
        with_options: [
          "Department for Tests (DfT)",
          "Ministry Of Testing (MOT)",
          "Test Org (TO)",
        ],
      )
    end

    it "has access fields" do
      expect(rendered).to have_checked_field("Permitted")
      expect(rendered).to have_unchecked_field("Denied")
    end
  end

  context "with a user with no name set" do
    let(:user) { build(:user, :with_no_name, id: 1) }

    it "shows no name set" do
      expect(rendered).to have_text("No name set")
    end
  end

  context "with a user with an unknown organisation" do
    let(:user) { build(:user, :with_unknown_org, id: 1) }

    it "shows the organisation slug" do
      expect(rendered).to have_text("unknown-org")
    end

    it "shows no organisation set" do
      expect(rendered).to have_text("No organisation set")
    end

    it "prompts super admin to choose organisation" do
      expect(rendered).to have_select("Organisation", with_options: ["Select an organisation"])
    end
  end

  context "with a user with no organisation set" do
    let(:user) { build(:user, :with_no_org, id: 1) }

    it "shows no organisation set" do
      expect(rendered).to have_text("No organisation set")
    end

    it "prompts super admin to choose organisation" do
      expect(rendered).to have_select("Organisation", with_options: ["Select an organisation"])
    end
  end

  context "with a user where organisation has not signed MOU" do
    it "shows MOU banner" do
      expect(rendered).to have_text(I18n.t("users.edit.mou_banner"))
    end
  end

  context "with a user where organisation has signed MOU" do
    let(:user) { build :user, :org_has_signed_mou }

    it "does not show MOU banner" do
      expect(rendered).not_to have_text(I18n.t("users.edit.mou_banner"))
    end
  end
end
