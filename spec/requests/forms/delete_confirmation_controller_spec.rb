require "rails_helper"

RSpec.describe Forms::DeleteConfirmationController, type: :request do
  let(:form) { create(:form) }
  let(:page) { build(:page, form_id: form.id) }

  let(:group) { create(:group, organisation: standard_user.organisation) }
  let(:membership) { create :membership, group:, user: standard_user }

  before do
    membership
    GroupForm.create!(form_id: form.id, group_id: group.id)
    login_as_standard_user
  end

  describe "#delete" do
    describe "Given a valid form" do
      before do
        get delete_form_path(form_id: form.id)
      end

      context "when current user is not in group for form" do
        let(:membership) { nil }

        it "returns an error" do
          expect(response).to have_http_status :forbidden
        end
      end
    end
  end

  describe "#destroy" do
    describe "Given a valid form" do
      let(:form) { create(:form, name: "Form 1") }

      before do
        delete destroy_form_path(form_id: form.id, forms_delete_confirmation_input: { confirm: "yes" })
      end

      it "redirects you to the group page" do
        expect(response).to redirect_to(group_path(group))
      end

      it "deletes the form" do
        expect(Form.exists?(form.id)).to be false
      end

      it "displays a success flash message" do
        expect(flash[:success]).to eq "The draft form, ‘Form 1’, has been deleted"
      end

      context "when the form is live" do
        let(:form) { create(:form, :live) }

        it "deletes the form and redirects" do
          expect(response).to redirect_to(group_path(group))
          expect(Form.exists?(form.id)).to be false
        end
      end

      context "when current user is not in group for form" do
        let(:membership) { nil }

        it "returns an error" do
          expect(response).to have_http_status :forbidden
        end

        it "does not delete the form" do
          expect(Form.exists?(form.id)).to be true
        end
      end
    end

    context "when the user has decided not to delete the form" do
      before do
        delete destroy_form_path(form_id: form.id, forms_delete_confirmation_input: { confirm: "no" })
      end

      it "redirects you to the form page" do
        expect(response).to redirect_to(form_path(form.id))
      end

      it "does not delete the form" do
        expect(Form.exists?(form.id)).to be true
      end
    end

    context "when user has not confirmed whether they want to delete the form or not" do
      before do
        delete destroy_form_path(form_id: form.id, forms_delete_confirmation_input: { confirm: nil })
      end

      it "re-renders the confirm delete view with an error" do
        expect(response).to render_template(:delete)
        expect(response.body).to include "Select ‘Yes’ to delete the draft"
      end

      it "does not delete the form on the API" do
        expect(Form.exists?(form.id)).to be true
      end
    end

    describe "Given a form that is live with a draft" do
      let(:form) { create(:form, :live_with_draft, name: "Form 1") }
      let(:revert_service) { instance_double(RevertDraftFormService) }

      before do
        allow(RevertDraftFormService).to receive(:new).with(form).and_return(revert_service)
      end

      context "when user confirms deletion of the draft" do
        before do
          allow(revert_service).to receive(:revert_draft_from_form_document).with(:live).and_return(true)
          delete destroy_form_path(form_id: form.id, forms_delete_confirmation_input: { confirm: "yes" })
        end

        it "redirects to the live form page" do
          expect(response).to redirect_to(live_form_path(form.id))
        end

        it "reverts the draft to the live form" do
          expect(revert_service).to have_received(:revert_draft_from_form_document).with(:live)
        end

        it "displays a success flash message" do
          expect(flash[:success]).to eq "The draft form, ‘Form 1’, has been deleted"
        end
      end

      context "when reversion of draft fails" do
        before do
          allow(revert_service).to receive(:revert_draft_from_form_document).with(:live).and_return(false)
          delete destroy_form_path(form_id: form.id, forms_delete_confirmation_input: { confirm: "yes" })
        end

        it "redirects back to the form page" do
          expect(response).to redirect_to(form_path(form.id))
        end

        it "displays an error message" do
          expect(flash[:message]).to eq "Deletion unsuccessful"
        end
      end

      context "when user decides not to delete the draft" do
        before do
          delete destroy_form_path(form_id: form.id, forms_delete_confirmation_input: { confirm: "no" })
          allow(revert_service).to receive(:revert_draft_from_form_document)
        end

        it "redirects you to the form page" do
          expect(response).to redirect_to(form_path(form.id))
        end

        it "does not attempt to revert the draft" do
          expect(revert_service).not_to have_received(:revert_draft_from_form_document)
        end
      end

      context "when current user is not in group for form" do
        let(:membership) { nil }

        before do
          allow(revert_service).to receive(:revert_draft_from_form_document)
          delete destroy_form_path(form_id: form.id, forms_delete_confirmation_input: { confirm: "yes" })
        end

        it "returns an error" do
          expect(response).to have_http_status :forbidden
        end

        it "does not attempt to revert the draft" do
          expect(revert_service).not_to have_received(:revert_draft_from_form_document)
        end
      end
    end

    describe "Given a form that is archived with a draft" do
      let(:form) { create(:form, :archived_with_draft, name: "Form 1") }
      let(:revert_service) { instance_double(RevertDraftFormService) }

      before do
        allow(RevertDraftFormService).to receive(:new).with(form).and_return(revert_service)
      end

      context "when user confirms deletion of the draft" do
        before do
          allow(revert_service).to receive(:revert_draft_from_form_document).with(:archived).and_return(true)
          delete destroy_form_path(form_id: form.id, forms_delete_confirmation_input: { confirm: "yes" })
        end

        it "redirects to the archived form page" do
          expect(response).to redirect_to(live_form_path(form.id))
        end

        it "reverts the draft to the archived form" do
          expect(revert_service).to have_received(:revert_draft_from_form_document).with(:archived)
        end

        it "displays a success flash message" do
          expect(flash[:success]).to eq "The draft form, ‘Form 1’, has been deleted"
        end
      end

      context "when reversion of draft fails" do
        before do
          allow(revert_service).to receive(:revert_draft_from_form_document).with(:archived).and_return(false)
          delete destroy_form_path(form_id: form.id, forms_delete_confirmation_input: { confirm: "yes" })
        end

        it "redirects back to the form page" do
          expect(response).to redirect_to(form_path(form.id))
        end

        it "displays an error message" do
          expect(flash[:message]).to eq "Deletion unsuccessful"
        end
      end

      context "when user decides not to delete the draft" do
        before do
          delete destroy_form_path(form_id: form.id, forms_delete_confirmation_input: { confirm: "no" })
          allow(revert_service).to receive(:revert_draft_from_form_document)
        end

        it "redirects you to the form page" do
          expect(response).to redirect_to(form_path(form.id))
        end

        it "does not attempt to revert the draft" do
          expect(revert_service).not_to have_received(:revert_draft_from_form_document)
        end
      end

      context "when current user is not in group for form" do
        let(:membership) { nil }

        before do
          allow(revert_service).to receive(:revert_draft_from_form_document)
          delete destroy_form_path(form_id: form.id, forms_delete_confirmation_input: { confirm: "yes" })
        end

        it "returns an error" do
          expect(response).to have_http_status :forbidden
        end

        it "does not attempt to revert the draft" do
          expect(revert_service).not_to have_received(:revert_draft_from_form_document)
        end
      end
    end

    context "when the form is in an unhandled state" do
      let(:form) { create(:form, :archived, name: "Form 1") }

      before do
        allow(form).to receive_messages(draft?: false, live_with_draft?: false)
        delete destroy_form_path(form_id: form.id, forms_delete_confirmation_input: { confirm: "yes" })
      end

      it "redirects back with an error" do
        expect(response).to redirect_to(form_path(form.id))
        expect(flash[:message]).to eq "Deletion unsuccessful"
      end
    end
  end
end
