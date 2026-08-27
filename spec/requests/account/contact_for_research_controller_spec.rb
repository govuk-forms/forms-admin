require "rails_helper"

describe Account::ContactForResearchController do
  let(:user) { create(:user, name: nil, research_contact_status: "to_be_asked") }

  before do
    login_as user
  end

  describe "GET #edit" do
    context "when user adds a research contact status" do
      it "assigns a new ContactForResearchInput to @contact_for_research_input" do
        get edit_account_contact_for_research_path
        expect(assigns(:contact_for_research_input)).to be_a(Account::ContactForResearchInput)
      end
    end
  end

  describe "PUT #update" do
    context "with valid params" do
      let(:valid_params) { { account_contact_for_research_input: { research_contact_status: "consented" } } }

      before do
        # rubocop:disable RSpec/AnyInstance
        allow_any_instance_of(AfterSignInPathHelper).to receive(:after_sign_in_next_path).and_return("/next-path")
        # rubocop:enable RSpec/AnyInstance
      end

      it "updates the user's research contact status" do
        put account_contact_for_research_path, params: valid_params
        expect(user.reload.research_contact_status).to eq("consented")
      end

      it "redirects to the root path" do
        put account_contact_for_research_path, params: valid_params
        expect(response).to redirect_to("/next-path")
      end

      it "sends the user research invitation email" do
        expect {
          put account_contact_for_research_path, params: valid_params
        }.to change { ActionMailer::Base.deliveries.count }.by(1)
      end
    end

    context "with invalid params" do
      let(:invalid_params) { { account_contact_for_research_input: { research_contact_status: "" } } }

      it "does not update the user's research contact status" do
        put account_contact_for_research_path, params: invalid_params
        expect(user.reload.research_contact_status).to eq("to_be_asked")
      end

      it "renders the edit template" do
        put account_contact_for_research_path, params: invalid_params
        expect(response).to have_http_status(:unprocessable_content)
        expect(response).to render_template(:edit)
      end
    end
  end
end
