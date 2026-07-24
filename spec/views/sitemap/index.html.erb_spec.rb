require "rails_helper"

describe "sitemap/index.html.erb" do
  let(:locals) { { active_groups: [], trial_groups: [], should_show_users_link: false, should_show_organisations_link: false, should_show_reports_link: false } }

  def render_template
    render template: "sitemap/index", locals:
  end

  describe "page title" do
    it "matches the heading" do
      render_template
      expect(view.content_for(:title)).to eq "Sitemap"
    end
  end

  it "contains page heading" do
    render_template
    expect(rendered).to have_css("h1.govuk-heading-l", text: "Sitemap")
  end

  it "includes groups" do
    render_template
    expect(rendered).to have_link("Your groups", href: groups_path)
  end

  context "when there are active groups" do
    let(:active_group) { build_stubbed(:group, id: 1, name: "Active Group 1") }
    let(:locals) { super().merge(active_groups: [active_group]) }

    it "includes active groups" do
      render_template

      expect(rendered).to have_text("Active groups:")
      expect(rendered).to have_link("Group 1", href: group_path(locals[:active_groups].first))
    end
  end

  context "when there are trial groups" do
    let(:trial_group) { build_stubbed(:group, id: 1, name: "Trial Group 1") }
    let(:locals) { super().merge(trial_groups: [trial_group]) }

    it "includes trial groups" do
      render_template

      expect(rendered).to have_text("Trial groups:")
      expect(rendered).to have_link("Trial Group 1", href: group_path(locals[:trial_groups].first))
    end
  end

  context "when there are no groups" do
    let(:locals) { super().merge(active_groups: [], trial_groups: []) }

    it "does not include groups" do
      render_template

      expect(rendered).not_to have_text("Active groups:")
      expect(rendered).not_to have_text("Trial groups:")
    end
  end

  context "when the should_show_organisations_link is true" do
    let(:locals) { super().merge(should_show_organisations_link: true) }

    it "includes a link to the organisations page" do
      render_template

      expect(rendered).to have_link("Organisations", href: organisations_path)
    end

    it "includes a link to the MOU signing page" do
      render_template

      expect(rendered).to have_link("Memorandum of Understanding", href: mou_signature_url)
    end
  end

  context "when should_show_organisations_link is false" do
    let(:locals) { super().merge(should_show_organisations_link: false) }

    it "does not include a link to the organisations page" do
      render_template

      expect(rendered).not_to have_link("Organisations")
    end

    it "does not include a link to the MOU signing page" do
      render_template

      expect(rendered).not_to have_link("Memorandum of Understanding")
    end
  end

  context "when the should_show_users_link is true" do
    let(:locals) { super().merge(should_show_users_link: true) }

    it "includes a link to the users page" do
      render_template

      expect(rendered).to have_link("Users", href: users_path)
    end
  end

  context "when the should_show_reports_link is true" do
    let(:locals) { super().merge(should_show_reports_link: true) }

    it "includes a link to the reports page" do
      render_template

      expect(rendered).to have_link("Reports", href: reports_path)
    end
  end
end
