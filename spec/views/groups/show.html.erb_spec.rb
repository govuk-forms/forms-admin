require "rails_helper"

RSpec.describe "groups/show", type: :view do
  let(:current_user) { create :user, :org_has_signed_mou }
  let(:forms) { [] }
  let(:group) { create :group, name: "My Group", organisation: current_user.organisation }

  let(:form_list_presenter) { FormListPresenter.call(forms:, group:) }

  let(:membership_role) { :editor }
  let(:upgrade?) { false }
  let(:edit?) { true }
  let(:move?) { false }
  let(:delete?) { false }
  let(:manage_feature_flags?) { false }
  let(:request_upgrade?) { false }
  let(:review_upgrade?) { false }

  before do
    create :membership, group:, user: current_user, role: membership_role, added_by: current_user

    assign(:current_user, current_user)
    assign(:group, group)
    assign(:forms, forms)
    assign(:form_list_presenter, form_list_presenter)

    without_partial_double_verification do
      policy_double = instance_double(GroupPolicy,
                                      upgrade?: upgrade?,
                                      edit?: edit?,
                                      delete?: delete?,
                                      move?: move?,
                                      manage_feature_flags?: manage_feature_flags?,
                                      request_upgrade?: request_upgrade?,
                                      review_upgrade?: review_upgrade?)

      allow(view).to receive(:policy).and_return(policy_double)
    end

    render
  end

  it "renders the group name in <h1>" do
    expect(rendered).to have_css "h1.govuk-heading-l", text: "My Group"
  end

  it "renders the status of the group" do
    expect(rendered).to have_css ".govuk-caption-l", text: t("groups.status_caption.trial")
  end

  it "has a link to the change group name page" do
    expect(rendered).to have_link "Change the name of this group", href: edit_group_path(group)
  end

  it "has a link to the edit members page" do
    expect(rendered).to have_link "Edit members of this group", href: group_members_path(group)
  end

  context "when the user does not have permission to edit the group" do
    let(:edit?) { false }

    it "does not have a link to the change group name page" do
      expect(rendered).not_to have_link "Change the name of this group", href: edit_group_path(group)
    end

    it "has a link to the review members page" do
      expect(rendered).to have_link "View members of this group", href: group_members_path(group)
    end
  end

  context "when the user has permission to move the group" do
    let(:move?) { true }

    it "has a link to move the group" do
      expect(rendered).to have_link("Move this group to another organisation")
    end
  end

  context "when the user has permission to manage feature flags" do
    let(:manage_feature_flags?) { true }

    it "has a link to manage feature flags" do
      expect(rendered).to have_link("Manage feature flags for this group", href: feature_flags_group_path(group))
    end
  end

  context "when the user does not have permission to manage feature flags" do
    let(:manage_feature_flags?) { false }

    it "does not have a link to manage feature flags" do
      expect(rendered).not_to have_link("Manage feature flags for this group")
    end
  end

  context "when the user does not have permission to move the group" do
    it "does not have a link to the move group page" do
      expect(rendered).not_to have_link("Move this group to another organisation")
    end
  end

  context "when the group has no forms" do
    let(:form_list_presenter) { nil }

    before { assign(:form_list_presenter, form_list_presenter) }

    it "does not have a table of forms" do
      expect(rendered).not_to have_table
    end
  end

  context "when the group has one of more forms" do
    let(:forms) do
      [
        build(:form, id: 1, name: "Form 1", created_at: "2024-10-08T07:31:15.762Z"),
        build(:form, :live, id: 2, name: "Form 2", created_at: "2024-10-08T07:31:15.762Z"),
        build(:form, :live_with_draft, id: 3, name: "Form 3", created_at: "2024-10-08T07:31:15.762Z"),
      ]
    end

    it "renders a table listing the forms in a scrollable wrapper" do
      wrapper = Capybara.string(rendered.html).find(".app-scrolling-wrapper")
      expect(wrapper).to have_table "Forms in ‘My Group’"
      expect(wrapper).to have_css "tbody .govuk-table__row", count: 3
    end

    it "renders a link for each form" do
      expect(rendered).to have_link("Form 1", href: form_path(1))
      expect(rendered).to have_link("Form 2", href: live_form_path(2))
      expect(rendered).to have_link("Form 3", href: live_form_path(3))
    end

    it "renders a status tag for each form" do
      page = Capybara.string(rendered.html)
      table_rows = page.find_all("tbody .govuk-table__row")
      status_tags = table_rows.map do |row|
        row.find_all(".govuk-tag").map do |status_tag|
          {
            text: status_tag.text,
            colour: status_tag[:class].delete_prefix("govuk-tag govuk-tag--").strip,
          }
        end
      end

      expect(status_tags).to eq [
        [{ text: "Draft", colour: "yellow" }],
        [{ text: "Live", colour: "teal" }],
        [{ text: "Draft", colour: "yellow" }, { text: "Live", colour: "teal" }],
      ]
    end
  end

  context "when the group is a trial group" do
    let(:group) { create :group, :trial, name: "trial group", organisation: current_user.organisation }

    it "renders the status of the group" do
      expect(rendered).to have_css ".govuk-caption-l", text: t("groups.status_caption.trial")
    end

    it "shows a notification banner" do
      expect(rendered).to have_css ".govuk-notification-banner"
    end

    it "has the trial group heading in the notification banner" do
      expect(rendered).to have_css "h3", text: "This is a ‘trial’ group"
    end

    context "when the group's organisation has signed an MOU" do
      let(:group) { create :group, organisation: }
      let(:current_user) { create :user, organisation: }
      let(:organisation) { create :organisation, :with_signed_mou }

      context "and the organisation has an organisation admin" do
        let(:organisation) { create :organisation, :with_signed_mou, :with_org_admin }

        context "and the user has permission to review upgrade requests" do
          let(:review_upgrade?) { true }
          let(:upgrade?) { true }
          let(:request_upgrade?) { true }
          let(:upgrade_requester) { create :user, organisation: }
          let(:group) { create :group, organisation:, status: :upgrade_requested, upgrade_requester: }

          it "has the heading in the notification banner for reviewing an upgrade request" do
            expect(rendered).to have_css "h3", text: "A group admin has asked to upgrade this group"
          end

          it "has the content in the notification banner for reviewing an upgrade request" do
            expect(rendered).to have_text "#{upgrade_requester.name} has asked to upgrade this group so they can make forms live."
          end

          it "shows a link to review the upgrade" do
            expect(rendered).to have_link("Accept or reject this upgrade request", href: review_upgrade_group_path(group))
          end
        end

        context "when the user has permission to upgrade the group" do
          let(:upgrade?) { true }
          let(:request_upgrade?) { true }

          it "shows content for an organisation admin" do
            expect(rendered).to have_text "Forms in this group cannot be made live unless the group is upgraded to an ‘active’ group."
          end

          it "shows a link to upgrade the group" do
            expect(rendered).to have_link("Upgrade this group", href: upgrade_group_path(group))
          end

          it "has the trial group heading in the notification banner" do
            expect(rendered).to have_css "h3", text: "This is a ‘trial’ group"
          end
        end

        context "and the user has permission to request an upgrade" do
          let(:request_upgrade?) { true }

          it "shows content for a group admin" do
            expect(rendered).to have_text "You can create forms in this group and test them, but you cannot make them live."
          end

          it "shows a link to request an upgrade" do
            expect(rendered).to have_link("Find out how to make forms live", href: request_upgrade_group_path(group))
          end

          it "has the trial group heading in the notification banner" do
            expect(rendered).to have_css "h3", text: "This is a ‘trial’ group"
          end
        end

        context "and the user has no permissions relating to upgrading groups" do
          it "shows content for an editor" do
            expect(rendered).to have_text "You can create a form, preview and test it."
          end
        end
      end

      context "and the organisation does not have an organisation admin" do
        context "and the user has permission to request an upgrade" do
          let(:request_upgrade?) { false } # false because GroupPolicy depends on state of group as well as user permissions
          let(:membership_role) { :group_admin }

          it "shows content for a group admin" do
            expect(rendered).to have_text "You can create forms in this group and test them, but you cannot make them live."
          end

          it "does not show a link to request an upgrade" do
            expect(rendered).not_to have_link("Find out how to upgrade this group so you can make forms live", href: request_upgrade_group_path(group))
          end

          it "shows the MOU and org admin requirements" do
            expect(rendered).to include(I18n.t("groups.show.trial_banner.request_upgrade.organisation_requirements_html"))
          end

          it "shows a link to contact the GOV.UK Forms team" do
            expect(rendered).to have_link("contact the GOV.UK Forms team", href: contact_url)
          end

          it "has the trial group heading in the notification banner" do
            expect(rendered).to have_css "h3", text: "This is a ‘trial’ group"
          end
        end

        context "when the user has permission to upgrade the group" do
          let(:upgrade?) { true }

          it "shows content for an organisation admin" do
            expect(rendered).to have_text "Forms in this group cannot be made live unless the group is upgraded to an ‘active’ group."
          end

          it "shows a link to upgrade the group" do
            expect(rendered).to have_link("Upgrade this group", href: upgrade_group_path(group))
          end

          it "has the trial group heading in the notification banner" do
            expect(rendered).to have_css "h3", text: "This is a ‘trial’ group"
          end
        end

        context "and the user has no permissions relating to upgrading groups" do
          it "shows content for an editor" do
            expect(rendered).to have_text "You can create a form, preview and test it."
          end
        end
      end
    end

    context "and the org has not signed an MOU" do
      let(:current_user) { create :user }

      context "when the user is a super admin" do
        let(:current_user) { create :super_admin_user }

        it "shows content for organisation requiring an MOU" do
          expect(rendered).to have_text("Someone from your organisation needs to agree to a ‘Memorandum of Understanding’ with GOV.UK Forms before your organisation can make any forms live.")
        end
      end

      context "and the user has permission to request an upgrade" do
        let(:request_upgrade?) { true }

        it "shows content for a group admin" do
          expect(rendered).to have_text "You can create forms in this group and test them, but you cannot make them live."
        end

        it "shows the MOU and org admin requirements" do
          expect(rendered).to include(I18n.t("groups.show.trial_banner.request_upgrade.organisation_requirements_html"))
        end

        it "does not show a link to request an upgrade" do
          expect(rendered).not_to have_link("Find out how to upgrade this group so you can make forms live", href: request_upgrade_group_path(group))
        end

        it "shows a link to contact the GOV.UK Forms team" do
          expect(rendered).to have_link("contact the GOV.UK Forms team", href: contact_url)
        end

        it "has the trial group heading in the notification banner" do
          expect(rendered).to have_css "h3", text: "This is a ‘trial’ group"
        end
      end

      context "and the user is a group admin" do
        let(:membership_role) { :group_admin }

        context "and the organisation has no admin" do
          let(:request_upgrade?) { false } # false because GroupPolicy depends on state of group as well as user permissions

          it "shows content for a group admin" do
            expect(rendered).to have_text "You can create forms in this group and test them, but you cannot make them live."
          end

          it "shows the MOU and org admin requirements" do
            expect(rendered).to include(I18n.t("groups.show.trial_banner.request_upgrade.organisation_requirements_html"))
          end

          it "does not show a link to request an upgrade" do
            expect(rendered).not_to have_link("Find out how to upgrade this group so you can make forms live", href: request_upgrade_group_path(group))
          end

          it "shows a link to contact the GOV.UK Forms team" do
            expect(rendered).to have_link("contact the GOV.UK Forms team", href: contact_url)
          end

          it "has the trial group heading in the notification banner" do
            expect(rendered).to have_css "h3", text: "This is a ‘trial’ group"
          end
        end
      end

      context "and the user has no permissions relating to upgrading groups" do
        it "shows content for an editor" do
          expect(rendered).to have_text "You can create a form, preview and test it."
        end
      end
    end
  end

  context "when the group has an upgrade requested" do
    let(:group) { create :group, :upgrade_requested, organisation: current_user.organisation }

    it "have the caption trial group" do
      expect(rendered).to have_css ".govuk-caption-l", text: "Trial group"
    end

    it "shows a notification banner" do
      expect(rendered).to have_css ".govuk-notification-banner"
    end

    it "has the trial group heading in the notification banner" do
      expect(rendered).to have_css "h3", text: "This is a ‘trial’ group"
    end
  end

  context "when the group is an active group" do
    let(:group) { create :group, :active, name: "Active group", organisation: current_user.organisation }

    it "renders the status of the group" do
      expect(rendered).to have_css ".govuk-caption-l", text: t("groups.status_caption.active")
    end

    it "does not show a notification banner" do
      expect(rendered).not_to have_css ".govuk-notification-banner"
    end
  end

  it "has a start button to create a new form" do
    render
    expect(rendered).to have_css ".govuk-button--start", text: "Create a form" do |start_button|
      expect(start_button).to match_selector :link, href: new_group_form_path(group)
    end
  end

  describe "delete button" do
    shared_examples "deletable" do
      it "has a button to delete the group" do
        expect(rendered).to have_link "Delete this group", class: "govuk-button--warning", href: delete_group_path(group)
      end
    end

    shared_examples "not deletable" do
      it "does not have a button to delete the group" do
        expect(rendered).not_to have_link href: delete_group_path(group)
      end
    end

    context "when the group has no forms" do
      let(:form_list_presenter) { nil }

      context "and the user has permission to delete the group" do
        let(:delete?) { true }

        it_behaves_like "deletable"
      end

      context "and the user does not have permission to delete the group" do
        let(:delete?) { false }

        it_behaves_like "not deletable"
      end
    end

    context "and the group has some forms" do
      context "and the user has permission to delete the group" do
        let(:delete?) { true }

        it_behaves_like "not deletable"
      end

      context "and the user does not have permission to delete the group" do
        let(:delete?) { false }

        it_behaves_like "not deletable"
      end
    end
  end

  describe "Details component manage group" do
    let(:organisation) { create(:organisation) }
    let(:group) { create(:group, organisation:) }
    let(:current_user) { create(:user, organisation:) }

    def details
      Capybara.string(rendered).find(".govuk-details")
    end

    context "when the organisation does not have admin users" do
      before do
        create(:mou_signature_for_organisation, organisation:)
      end

      it "does not render the details component" do
        expect(rendered).not_to have_css("details.govuk-details")
      end
    end

    context "when the organisation has not signed the MOU" do
      before do
        # We have to delete it rather because it's hard to create an org with
        # an admin but no MOU
        group.organisation.mou_signatures.destroy_all
      end

      it "does not render the details component" do
        expect(rendered).not_to have_css("details.govuk-details")
      end
    end

    context "when the organisation has admin users and has signed the MOU" do
      let(:organisation) { create(:organisation, :with_org_admin) }

      it "renders the details component with the correct summary text" do
        expect(rendered).to have_css("details.govuk-details .govuk-details__summary-text", text: t("groups.show.details.title"))
      end

      context "when the current user is an organisation admin" do
        let(:current_user) { create :user, :organisation_admin, organisation: }

        context "and the group is active" do
          let(:group) { create :group, :active, organisation: }

          it "shows content for an org admin about an active group" do
            expected_text = Capybara.string(t("groups.show.details.org_admin.active_group_summary_html")).text
            expect(details).to have_text(expected_text)
          end
        end

        context "and the group is a trial group" do
          let(:group) { create :group, :trial, organisation: }

          it "shows content for an org admin about a trial group" do
            expected_text = Capybara.string(t("groups.show.details.org_admin.trial_group_summary_html")).text
            expect(details).to have_text(expected_text)
          end
        end
      end

      context "when the current user is a standard user" do
        let(:current_user) { create :user, :standard, organisation: }

        context "and the group is active" do
          let(:group) { create :group, :active, organisation: }

          it "shows content for a standard user about an active group" do
            expected_text = Capybara.string(t("groups.show.details.standard_user.active_group_summary_html")).text
            expect(details).to have_text(expected_text)
          end

          it "lists the organisation's admin users" do
            admin_user_email = group.organisation.admin_users.first.email
            expect(details).to have_text(admin_user_email)
          end
        end

        context "and the group is a trial group" do
          let(:group) { create :group, :trial, organisation: }

          it "shows content for a standard user about a trial group" do
            expected_text = Capybara.string(t("groups.show.details.standard_user.trial_group_summary_html")).text
            expect(details).to have_text(expected_text)
          end

          it "lists the organisation's admin users" do
            admin_user_email = group.organisation.admin_users.first.email
            expect(details).to have_text(admin_user_email)
          end
        end
      end

      context "when the current user is a super admin" do
        let(:current_user) { create :super_admin_user, organisation: }

        it "does not render the details component" do
          expect(rendered).not_to have_css("details.govuk-details")
        end
      end
    end
  end
end
