require "rails_helper"

describe Account::OrganisationsController do
  let(:domain) { "example.gov.uk" }
  let(:user) { create(:user, :with_no_org, email: Faker::Internet.email(domain: domain)) }

  before do
    login_as user
  end

  describe "GET #edit" do
    context "when there is more than one organisation the user can select" do
      context "when the user does not have an organisation" do
        it "assign the input object with allowed organisations limited by the user's domain" do
          matching_orgs = [
            create(:organisation, organisation_domains: [create(:organisation_domain, domain: domain)]),
            create(:organisation, organisation_domains: [create(:organisation_domain, domain: domain)]),
          ]
          create(:organisation, organisation_domains: [create(:organisation_domain, domain: "example.com")])
          create(:organisation, closed: true, organisation_domains: [create(:organisation_domain, domain: domain)])

          get edit_account_organisation_path

          expect(response).to render_template(:edit)

          input_object = assigns(:organisation_input)
          expect(input_object).to be_a(Account::OrganisationInput)
          expect(input_object.allowed_organisations).to match_array(matching_orgs)
        end

        context "when there are no organisations the user can select" do
          it "renders the no_matches template" do
            get edit_account_organisation_path
            expect(response).to render_template(:no_matches)
          end
        end

        context "when there is only one organisation the user can select" do
          it "redirects to the confirm organisation path" do
            create(:organisation, organisation_domains: [create(:organisation_domain, domain: domain)])

            get edit_account_organisation_path
            expect(response).to redirect_to(show_confirm_account_organisation_path)
          end
        end
      end

      context "when the user already has an organisation" do
        let(:user) { create(:user) }

        it "redirects to the root path" do
          get edit_account_organisation_path
          expect(response).to redirect_to(root_path)
        end
      end
    end
  end

  describe "PUT #update" do
    context "with valid parameters" do
      let(:organisation) { create(:organisation, organisation_domains: [create(:organisation_domain, domain: domain)]) }
      let(:valid_params) { { account_organisation_input: { organisation_id: organisation.id } } }

      before do
        # rubocop:disable RSpec/AnyInstance
        allow_any_instance_of(AfterSignInPathHelper).to receive(:after_sign_in_next_path).and_return("/next-path")
        # rubocop:enable RSpec/AnyInstance
      end

      it "updates the user's organisation" do
        put account_organisation_path, params: valid_params
        expect(user.reload.organisation).to eq(organisation)
      end

      it "redirects to the root path" do
        put account_organisation_path, params: valid_params
        expect(response).to redirect_to("/next-path")
      end
    end

    context "when the not listed radio option is selected" do
      let(:params) { { account_organisation_input: { organisation_id: Account::OrganisationInput::NOT_LISTED_OPTION_VALUE } } }

      before do
        create(:organisation, organisation_domains: [create(:organisation_domain, domain: domain)])
      end

      it "renders the no_matches template" do
        put account_organisation_path, params: params
        expect(response).to render_template(:no_matches)
      end

      it "does not update the user's organisation" do
        expect {
          put account_organisation_path, params: params
        }.not_to(change { user.reload.organisation })
      end
    end

    context "with invalid parameters" do
      let(:invalid_params) { { account_organisation_input: { organisation_id: nil } } }

      before do
        create(:organisation, organisation_domains: [create(:organisation_domain, domain: domain)])
      end

      it "does not update the user's organisation" do
        expect {
          put account_organisation_path, params: invalid_params
        }.not_to(change { user.reload.organisation })
      end

      it "re-renders the edit template" do
        put account_organisation_path, params: invalid_params
        expect(response).to have_http_status(:unprocessable_content)
        expect(response).to render_template(:edit)
      end
    end

    context "when the selected organisation does not match the user's email domain" do
      let(:organisation) { create(:organisation, organisation_domains: [create(:organisation_domain, domain: "other.gov.uk")]) }
      let(:invalid_params) { { account_organisation_input: { organisation_id: organisation.id } } }

      before do
        create(:organisation, organisation_domains: [create(:organisation_domain, domain: domain)])
      end

      it "does not update the user's organisation" do
        expect {
          put account_organisation_path, params: invalid_params
        }.not_to(change { user.reload.organisation })
      end

      it "re-renders the edit template" do
        put account_organisation_path, params: invalid_params
        expect(response).to have_http_status(:unprocessable_content)
        expect(response).to render_template(:edit)
      end
    end

    context "when there are no organisations the user can select" do
      it "renders the no_matches template" do
        put account_organisation_path, params: {}
        expect(response).to render_template(:no_matches)
      end
    end
  end

  describe "GET #show_confirm" do
    context "when there is only one organisation the user can select" do
      let!(:organisation) { create(:organisation, organisation_domains: [create(:organisation_domain, domain: domain)]) }

      it "renders the confirm template" do
        get show_confirm_account_organisation_path
        expect(response).to render_template(:confirm)

        input_object = assigns(:confirm_organisation_input)
        expect(input_object).to be_a(Account::ConfirmOrganisationInput)
        expect(input_object.organisation).to eq(organisation)
      end
    end

    context "when there are no organisations the user can select" do
      it "renders the no_matches template" do
        get show_confirm_account_organisation_path
        expect(response).to render_template(:no_matches)
      end
    end

    context "when there is more than one organisation the user can select" do
      before do
        create(:organisation, organisation_domains: [create(:organisation_domain, domain: domain)])
        create(:organisation, organisation_domains: [create(:organisation_domain, domain: domain)])
      end

      it "redirects to the edit route" do
        get show_confirm_account_organisation_path
        expect(response).to redirect_to edit_account_organisation_path
      end
    end
  end

  describe "POST #confirm" do
    let(:params) { { account_confirm_organisation_input: { confirm: "yes" } } }

    context "when there is only one organisation the user can select" do
      let!(:organisation) { create(:organisation, organisation_domains: [create(:organisation_domain, domain: domain)]) }

      context "when 'yes' is selected" do
        before do
          # rubocop:disable RSpec/AnyInstance
          allow_any_instance_of(AfterSignInPathHelper).to receive(:after_sign_in_next_path).and_return("/next-path")
          # rubocop:enable RSpec/AnyInstance
        end

        it "updates the user's organisation and redirects to the next path" do
          post confirm_account_organisation_path, params: params
          expect(user.reload.organisation).to eq(organisation)
          expect(response).to redirect_to("/next-path")
        end
      end

      context "when 'no' is selected" do
        let(:params) { { account_confirm_organisation_input: { confirm: "no" } } }

        it "renders the no_matches template and does not update the user's organisation" do
          post confirm_account_organisation_path, params: params
          expect(user.reload.organisation).to be_nil
          expect(response).to render_template(:no_matches)
        end
      end

      context "when the params are invalid" do
        let(:params) { { account_confirm_organisation_input: { confirm: "" } } }

        it "renders the confirm template with an error message" do
          post confirm_account_organisation_path, params: params
          expect(user.reload.organisation).to be_nil
          expect(response).to have_http_status(:unprocessable_content)
          expect(response).to render_template(:confirm)

          error = I18n.t("activemodel.errors.models.account/confirm_organisation_input.attributes.confirm.blank", organisation: organisation.name_with_abbreviation)
          expect(response.body).to include(error)
        end
      end
    end

    context "when there are no organisations the user can select" do
      it "renders the no_matches template" do
        post confirm_account_organisation_path, params: params
        expect(response).to render_template(:no_matches)
      end
    end

    context "when there is more than one organisation the user can select" do
      before do
        create(:organisation, organisation_domains: [create(:organisation_domain, domain: domain)])
        create(:organisation, organisation_domains: [create(:organisation_domain, domain: domain)])
      end

      it "redirects to the edit route" do
        post confirm_account_organisation_path, params: params
        expect(response).to redirect_to edit_account_organisation_path
      end
    end
  end
end
