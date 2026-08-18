require "rails_helper"

RSpec.describe UsersController, type: :request do
  let!(:charlie) do
    test_org.users.first.tap do |user|
      user.update(name: "Charlie", email: "charlie@example.gov.uk")
    end
  end
  let!(:andy) { create :user, name: "Andy Test", email: "andy-123@example.gov.uk", organisation: test_org }
  let!(:bob) { create :user, name: "Bob Test", email: "bob-123@example.gov.uk", organisation: test_org }

  describe "#index" do
    context "when logged in as a super admin" do
      let(:params) { {} }

      before do
        login_as_super_admin_user
      end

      context "when no filters are specified" do
        before do
          get users_path, params:
        end

        it "returns http code 200" do
          expect(response).to have_http_status(:ok)
        end

        it "renders the correct page" do
          expect(response.body).to include("Users")
          expect(response).to render_template("users/index")
        end

        it "assigns sorted users" do
          expect(assigns[:users]).to eq [super_admin_user, andy, bob, charlie]
        end
      end

      context "when filters are specified" do
        let(:organisation_id_raw) { test_org.name }
        let(:params) do
          {
            filter: {
              search: "123",
              organisation_id: test_org.id,
              organisation_id_raw:,
              role: "standard",
              has_access: "true",
            },
          }
        end

        before do
          # create users that won't match the filters
          create :user, name: "Diana Test", email: "diana@example.gov.uk", organisation: test_org
          create :user, name: "Emily Test", email: "emily-123@example.gov.uk", organisation: test_org, has_access: false
          create :user, name: "Frank Test", email: "frank-123@example.gov.uk", organisation: test_org, role: :organisation_admin

          other_org = create(:organisation, slug: "other-org")
          create(:user, name: "Gina Test", email: "gina-123@example.gov.uk", organisation: other_org)

          get users_path, params:
        end

        it "only assigns users that match the filters" do
          expect(assigns[:users]).to eq [andy, bob]
        end

        it "populates the filter input object" do
          filter_input = assigns[:filter_input]
          expect(filter_input.search).to eq "123"
          expect(filter_input.organisation_id).to eq test_org.id.to_s
          expect(filter_input.role).to eq "standard"
          expect(filter_input.has_access).to eq "true"
        end

        it "assigns filtered download path" do
          path = assigns[:filtered_download_path]
          parsed_params = CGI.parse(URI.parse(path).query)
          expect(parsed_params).to match(
            "filter[search]" => %w[123],
            "filter[organisation_id]" => [test_org.id.to_s],
            "filter[role]" => %w[standard],
            "filter[has_access]" => %w[true],
          )
        end

        context "when the organisation_id_raw filter is not specified" do
          let(:organisation_id_raw) { "" }

          it "does not filter using the organisation_id" do
            expect(assigns[:users].size).to eq 3
          end

          it "does not set the organisation_id on the input object" do
            filter_input = assigns[:filter_input]
            expect(filter_input.organisation_id).to be_nil
          end

          it "does not include the organisation_id in the filtered download path" do
            path = assigns[:filtered_download_path]
            parsed_params = CGI.parse(URI.parse(path).query)
            expect(parsed_params).to match(
              "filter[search]" => %w[123],
              "filter[organisation_id]" => [],
              "filter[role]" => %w[standard],
              "filter[has_access]" => %w[true],
            )
          end
        end
      end
    end

    context "when logged in with standard role" do
      it "is forbidden" do
        login_as_standard_user
        get users_path
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "#download" do
    context "when logged in as a super admin" do
      before do
        login_as_super_admin_user
        travel_to Time.utc(2025, 5, 15, 15, 31, 57)
      end

      context "when no filters are specified" do
        before do
          get download_users_path
        end

        it "returns http code 200" do
          expect(response).to have_http_status(:ok)
        end

        it "has content-type text/csv" do
          expect(response.headers["content-type"]).to eq "text/csv; charset=iso-8859-1"
        end

        it "responds with an attachment content-disposition header" do
          expect(response.headers["content-disposition"]).to match("attachment; filename=govuk_forms_users_2025-05-15 15:31:57 UTC.csv")
        end

        it "has expected response body" do
          csv = CSV.parse(response.body, headers: true)
          expect(csv.headers).to eq Users::CsvService::HEADERS
          expect(csv.length).to eq 4
        end
      end

      context "when filters are specified" do
        let(:params) do
          {
            filter: {
              search: "123",
              organisation_id: test_org.id,
              role: "standard",
              has_access: "true",
            },
          }
        end

        before do
          # create users that won't match the filters
          create :user, name: "Diana Test", email: "diana@example.gov.uk", organisation: test_org
          create :user, name: "Emily Test", email: "emily-123@example.gov.uk", organisation: test_org, has_access: false
          create :user, name: "Frank Test", email: "frank-123@example.gov.uk", organisation: test_org, role: :organisation_admin

          other_org = create(:organisation, slug: "other-org")
          create(:user, name: "Gina Test", email: "gina-123@example.gov.uk", organisation: other_org)

          get download_users_path, params:
        end

        it "has returns a CSV of the filtered users" do
          csv = CSV.parse(response.body, headers: true)
          expect(csv.length).to eq 2
          expect(csv[0]["Name"]).to eq andy.name
          expect(csv[1]["Name"]).to eq bob.name
        end
      end
    end

    context "when logged in with standard role" do
      it "is forbidden" do
        login_as_standard_user
        get download_users_path
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "#edit" do
    let(:user) { create(:user) }

    context "when logged in as a super admin" do
      before do
        login_as_super_admin_user
        get edit_user_path(user)
      end

      it "returns http code 200" do
        expect(response).to have_http_status(:ok)
      end

      it "renders the correct page" do
        expect(response).to render_template("users/edit")
      end
    end

    context "when logged in with standard role" do
      it "is forbidden" do
        login_as_standard_user
        get edit_user_path(user)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "#update" do
    let(:user) { create(:user) }
    let(:role) { :super_admin }

    context "when logged in as a super admin" do
      before do
        login_as_super_admin_user
      end

      it "redirects to /users page and updates user" do
        put user_path(user), params: { user: { role: } }
        expect(response).to redirect_to(users_path)
        expect(user.reload.super_admin?).to be true
      end

      it "can update the user's name" do
        patch user_path(user), params: { user: { name: "Fakey McFakeName" } }
        expect(user.reload.name).to eq "Fakey McFakeName"
      end

      it "can update whether user has access" do
        patch user_path(user), params: { user: { has_access: false } }
        expect(user.reload.has_access).to be false
      end

      it "when given a user which doesn't exist returns 404" do
        put user_path(-1), params: { user: { role: } }
        expect(response).to have_http_status(:not_found)
      end

      it "does not update user if role is invalid" do
        put user_path(user), params: { user: { role: nil } }
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include "Select a role for the user"
        expect(user.reload.role).not_to be_nil
      end

      context "when user has a name" do
        it "does not update user if name is cleared" do
          put user_path(user), params: { user: { name: nil } }
          expect(response).to have_http_status(:unprocessable_content)
          expect(response.body).to include "Enter the user’s name"
          expect(user.reload.organisation).not_to be_nil
        end
      end

      context "when user belongs to an organistion" do
        it "does not update user if organisation is not chosen" do
          put user_path(user), params: { user: { organisation_id: nil } }
          expect(response).to have_http_status(:unprocessable_content)
          expect(response.body).to include "Select the user’s organisation"
          expect(user.reload.organisation).not_to be_nil
        end
      end

      context "with a user with no name set" do
        let(:user) { create(:user, name: nil) }

        it "successfully updates the user when a name is not set" do
          put user_path(user), params: { user: { name: nil } }
          expect(response).to redirect_to(users_path)
          expect(user.reload.name).to be_nil
        end
      end

      context "with a user with no organisation set" do
        let(:user) { create(:user, organisation_id: nil) }

        it "does not return error if organisation is not chosen and role is not changed" do
          put user_path(user), params: { user: { organisation_id: nil } }
          expect(response).to redirect_to(users_path)
          expect(user.reload.organisation).to be_nil
        end

        it "returns an error if organisation is not chosen and role is changed to organisation_admin" do
          put user_path(user), params: { user: { role: "organisation_admin", organisation_id: nil } }
          expect(response).to have_http_status(:unprocessable_content)
          expect(user.reload.role).to eq("standard")
        end
      end

      [
        ["with an unknown organisation", :with_unknown_org],
        ["with no organisation set", :with_no_org],
      ].each do |(title, trait)|
        context "with a user #{title}" do
          let(:user) { create(:user, trait) }

          it "does not return error if organisation is not chosen" do
            put user_path(user), params: { user: { organisation_id: nil } }
            expect(response).to redirect_to(users_path)
            expect(user.reload.organisation).to be_nil
          end
        end
      end
    end

    context "when logged in with standard role" do
      it "is forbidden" do
        login_as_standard_user
        put user_path(user), params: { user: { role: "super_admin" } }
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when changing role" do
      before do
        login_as_super_admin_user
      end

      it "calls UserUpdateService" do
        user = create(:user)
        user_update_service = instance_spy(UserUpdateService)

        allow(UserUpdateService)
          .to receive(:new)
                .with(user, ActionController::Parameters.new(role: "organisation_admin").permit(:role))
                .and_return(user_update_service)

        patch user_path(user), params: { user: { role: "organisation_admin" } }

        expect(UserUpdateService)
          .to have_received(:new)
                .with(user, ActionController::Parameters.new(role: "organisation_admin").permit(:role))

        expect(user_update_service)
          .to have_received(:update_user)
      end
    end
  end
end
