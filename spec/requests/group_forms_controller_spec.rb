require "rails_helper"

RSpec.describe "/groups/:group_id/forms", type: :request do
  let(:group) { create :group, organisation:, status: :active }
  let(:organisation) { test_org }
  let(:nonexistent_group) { "foobar" }

  before do
    create(:membership, user: standard_user, group:)
    login_as_standard_user
  end

  describe "GET /new" do
    before do
      get new_group_form_url(group)
    end

    it "renders a successful response" do
      expect(response).to have_http_status :ok
    end

    it "renders the change name form" do
      assert_select "form[action=?][method=?]", group_forms_path, :post do
        assert_select "input[name=?]", "forms_name_input[name]"
      end
    end

    it "has a back link to the group page" do
      rendered = Capybara.string(response.body)
      expect(rendered).to have_link "Back", href: group_path(group)
    end

    context "when the current user does not have access to the group" do
      it "denies access" do
        other_group = create :group

        get new_group_form_url(other_group)

        expect(response).to have_http_status :forbidden
      end
    end

    context "when the group does not exist" do
      it "renders a 404 not found response" do
        get new_group_form_url(nonexistent_group)

        expect(response).to have_http_status :not_found
      end
    end
  end

  context "when moving forms" do
    let(:form) { build :form, id: 1 }

    before do
      create(:form, id: form.id)
      login_as_organisation_admin_user

      group.group_forms.create!(form_id: form.id)
      group.organisation = organisation_admin_user.organisation
      group.save!
    end

    describe "GET /edit" do
      it "returns 200 response" do
        get edit_group_form_url(group, id: form.id)

        expect(response).to have_http_status :ok
      end

      context "when the url is for a form that doesn't belong to the group" do
        it "returns 404 response" do
          other_group = create(:group, organisation: organisation_admin_user.organisation)
          get edit_group_form_url(other_group, id: form.id)

          expect(response).to have_http_status :not_found
        end
      end
    end

    describe "PATCH /update" do
      let(:other_group) { create(:group, organisation: organisation_admin_user.organisation) }

      context "with valid parameters" do
        it "redirects to the group" do
          patch group_form_url(group, id: form.id), params: { forms_group_select: { group: other_group.external_id } }

          expect(response).to redirect_to(group_url(group))
        end
      end

      context "with missing form group parameter" do
        it "re-renders the form with an error" do
          patch group_form_url(group, id: form.id), params: { forms_group_select: { group: nil } }

          expect(response).to have_http_status :unprocessable_content
        end
      end

      context "when the target group belongs to another organisation" do
        let(:other_organisation) { create(:organisation, slug: "other-org") }
        let(:other_org_group) { create(:group, organisation: other_organisation) }

        it "does not move the form" do
          expect {
            patch group_form_url(group, id: form.id), params: { forms_group_select: { group: other_org_group.external_id } }
          }.not_to(change { GroupForm.find_by(form_id: form.id).group })
        end

        it "renders a response with 422 status" do
          patch group_form_url(group, id: form.id), params: { forms_group_select: { group: other_org_group.external_id } }

          expect(response).to have_http_status :unprocessable_content
        end
      end

      context "when the form is live and the target group is not active" do
        let(:live_form) { create :form, :live, id: 2 }
        let(:trial_group) { create(:group, organisation: organisation_admin_user.organisation, status: :trial) }

        before do
          group.group_forms.create!(form_id: live_form.id)
        end

        it "does not move the form" do
          expect {
            patch group_form_url(group, id: live_form.id), params: { forms_group_select: { group: trial_group.external_id } }
          }.not_to(change { GroupForm.find_by(form_id: live_form.id).group })
        end

        it "renders a response with 422 status" do
          patch group_form_url(group, id: live_form.id), params: { forms_group_select: { group: trial_group.external_id } }

          expect(response).to have_http_status :unprocessable_content
        end
      end
    end
  end

  describe "POST /" do
    let(:valid_attributes) do
      { name: "Test form" }
    end
    let(:invalid_attributes) do
      { name: "" }
    end

    before do
      create(:organisation_admin_user, organisation:)
    end

    context "with valid parameters" do
      it "creates a form" do
        expect {
          post group_forms_url(group), params: { forms_name_input: valid_attributes }
        }.to change(Form, :count).by(1)
      end

      it "associates the new form with the group" do
        expect {
          post group_forms_url(group), params: { forms_name_input: valid_attributes }
        }.to change(GroupForm, :count).by(1)

        expect(GroupForm.last).to have_attributes(group_id: group.id, form_id: Form.last.id)
      end

      it "redirects to the created form" do
        post group_forms_url(group), params: { forms_name_input: valid_attributes }
        expect(response).to redirect_to(form_url(Form.last.id))
      end

      it "sends an email to the organisation admins" do
        post group_forms_url(group), params: { forms_name_input: valid_attributes }
        expect(ActionMailer::Base.deliveries.count).to eq(1)

        template_id = Settings.govuk_notify.admin_alerts.new_draft_form_created_template_id
        expect(ActionMailer::Base.deliveries.last.govuk_notify_template).to eq(template_id)
      end
    end

    context "with invalid parameters" do
      it "does not create a new form" do
        expect {
          post group_forms_url(group), params: { forms_name_input: invalid_attributes }
        }.not_to change(GroupForm, :count)
      end

      it "renders a response with 422 status" do
        post group_forms_url(group), params: { forms_name_input: invalid_attributes }
        expect(response).to have_http_status :unprocessable_content
      end

      it "renders the change name form with an error" do
        post group_forms_url(group), params: { forms_name_input: invalid_attributes }

        expect(assigns[:name_input]).to be_truthy
        expect(response).to render_template("group_forms/new")
        expect(response).to render_template("input_objects/forms/_name_input")
        expect(response.body).to include I18n.t("error_summary.heading")
      end

      it "does not send an email to the organisation admins" do
        post group_forms_url(group), params: { forms_name_input: invalid_attributes }
        expect(ActionMailer::Base.deliveries.count).to eq(0)
      end
    end

    context "when the current user does not have access to the group" do
      it "denies access" do
        other_group = create :group

        post group_forms_url(other_group), params: { forms_name_input: valid_attributes }

        expect(response).to have_http_status :forbidden
      end
    end

    context "when the group does not exist" do
      it "renders a 404 not found response" do
        post group_forms_url(nonexistent_group), params: { forms_name_input: valid_attributes }

        expect(response).to have_http_status :not_found
      end
    end
  end
end
