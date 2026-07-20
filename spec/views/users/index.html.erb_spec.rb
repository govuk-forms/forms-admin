require "rails_helper"

describe "users/index.html.erb" do
  let(:act_as_user_enabled) { false }
  let(:users) do
    build_list(:user, 3) do |user, i|
      user.id = i
    end
  end
  let(:filter_input) { Users::FilterInput.new }
  let(:filtered_download_path) { Faker::Internet.url }
  let(:pagy) { Pagy.new(count: users.size, page: 1, limit: 50) }

  before do
    allow(Settings).to receive(:act_as_user_enabled).and_return(act_as_user_enabled)

    create :organisation, :with_org_admin, slug: "test-org"
    create :organisation, :with_org_admin, slug: "ministry-of-testing"
    create :organisation, :with_org_admin, slug: "department-for-tests", name: "Department for Tests", abbreviation: "DfT"

    assign(:users, users)
    assign(:filter_input, filter_input)
    assign(:filtered_download_path, filtered_download_path)
    assign(:pagy, pagy)
    render template: "users/index"
  end

  it "contains page heading" do
    expect(rendered).to have_css("h1.govuk-heading-l", text: /Users/)
  end

  it "contains a scrollable wrapper with a table in it" do
    expect(rendered).to have_css(".app-scrolling-wrapper > table")
  end

  it "contains the total number of users" do
    expect(rendered).to have_css("p", text: "Showing 3 users")
  end

  context "when the users span multiple pages" do
    let(:pagy) { Pagy.new(count: 120, page: 1, limit: 50) }

    it "shows how many users are on this page out of the total" do
      expect(rendered).to have_css("p", text: "Showing 1 to 50 of 120 users")
    end
  end

  it "contains the user's name" do
    expect(rendered).to have_text(users.first.name)
  end

  it "contains the user's email as a link to the edit page" do
    expect(rendered).to have_link(users.first.email, href: edit_user_path(users.first))
  end

  it "contains organisation name" do
    expect(rendered).to have_text(users.first.organisation.name)
  end

  it "contains role" do
    expect(rendered).to have_text("Standard")
  end

  it "contains access" do
    expect(rendered).to have_text("Permitted")
  end

  context "with a user with no name set" do
    let(:users) { [build(:user, :with_no_name, id: 1)] }

    it "shows no name set" do
      expect(rendered).to have_text("No name set")
    end
  end

  context "with a user with an unknown organisation" do
    let(:users) { [build(:user, :with_unknown_org, id: 1)] }

    it "shows no organisation set" do
      expect(rendered).to have_text("No organisation set")
    end
  end

  context "with a user with no organisation set" do
    let(:users) { [build(:user, :with_no_org, id: 1)] }

    it "shows no organisation set" do
      expect(rendered).to have_text("No organisation set")
    end
  end

  context "when the act_as_user functionality is enabled" do
    let(:act_as_user_enabled) { true }

    it "contains Act as user" do
      expect(rendered).to have_text("Act as user")
    end

    it "contains an 'Act as this user' button" do
      expect(rendered).to have_button("Act as this user")
    end
  end

  describe "filter" do
    it "has organisation select" do
      expect(rendered).to have_select(
        "Organisation",
        with_options: [
          "Department for Tests (DfT)",
          "Ministry Of Testing (MOT)",
          "Test Org (TO)",
        ],
      )
    end

    context "when there are no filters applied" do
      it "does not have a link to clear the filters" do
        expect(rendered).not_to have_link("Clear filter")
      end
    end

    context "when there are filters applied" do
      let(:filter_input) { Users::FilterInput.new(name: "foo") }

      it "has a link to clear the filters" do
        expect(rendered).to have_link("Clear filter")
      end
    end
  end

  describe "csv download" do
    context "when there are no filters applied" do
      it "has a link to download all users" do
        expect(rendered).to have_link(t("users.index.download_all"), href: download_users_path)
      end
    end

    context "when there are filters applied" do
      let(:filter_input) { Users::FilterInput.new(name: "foo") }

      it "has a link to download filtered users" do
        expect(rendered).to have_link(t("users.index.download_filtered"), href: filtered_download_path)
      end
    end
  end
end
