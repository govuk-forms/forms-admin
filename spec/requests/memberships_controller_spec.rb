require "rails_helper"

describe "/memberships", type: :request do
  let(:user) { create(:user, organisation: standard_user.organisation) }
  let(:group) { create(:group, organisation: standard_user.organisation) }
  let(:logged_in_user_role) { :group_admin }

  before do
    create(:membership, user: standard_user, group:, role: logged_in_user_role)
    login_as_standard_user
  end

  describe "#destroy" do
    it "deletes a membership" do
      membership = create(:membership, user:, group:, added_by: standard_user)

      expect {
        delete membership_path(membership)
      }.to change(Membership, :count).by(-1)

      expect(response).to redirect_to(group_members_path(group.external_id))
    end

    context "when logged in user is not a group admin" do
      let(:logged_in_user_role) { :editor }

      it "does not delete a membership" do
        membership = create(:membership, user:, group:, added_by: standard_user)

        expect {
          delete membership_path(membership)
        }.not_to change(Membership, :count)

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "PUT #update" do
    let(:membership) { create(:membership, user:, group:) }
    let(:current_user) { organisation_admin_user }

    before do
      login_as current_user
    end

    context "with valid parameters" do
      let(:new_role) { "group_admin" }

      it "updates the membership role" do
        expect {
          put membership_path(membership), params: { membership: { role: new_role } }
        }.to change { membership.reload.role }.from("editor").to(new_role)
      end

      it "redirects to the group members page" do
        put membership_path(membership), params: { membership: { role: new_role } }
        expect(response).to redirect_to(group_members_path(group))
      end

      it "sets a success flash message" do
        put membership_path(membership), params: { membership: { role: new_role } }
        expect(flash[:success]).to eq(I18n.t("memberships.update.success.roles.#{new_role}", member_name: user.name))
      end
    end

    context "with invalid parameters" do
      let(:invalid_role) { "invalid_role" }

      it "does not update the membership role" do
        expect {
          put membership_path(membership), params: { membership: { role: invalid_role } }
        }.not_to(change { membership.reload.role })
      end

      it "redirects to the group members page" do
        put membership_path(membership), params: { membership: { role: invalid_role } }
        expect(response).to redirect_to(group_members_path(group))
      end
    end

    context "when not authorized" do
      let(:current_user) { standard_user }

      it "redirects to the root path" do
        put membership_path(membership), params: { membership: { role: "group_admin" } }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
