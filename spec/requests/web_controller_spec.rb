require "rails_helper"

RSpec.describe WebController, type: :request do
  let(:form) { create :form }

  before do
    login_as_standard_user
  end

  describe "logging", :capture_logging do
    let(:trace_id) { "Root=1-63441c4a-abcdef012345678912345678" }
    let(:request_id) { "a-request-id" }

    before do
      get root_path, headers: {
        "HTTP_X_AMZN_TRACE_ID": trace_id,
        "X-Request-ID": request_id,
      }
    end

    it "includes the trace ID on log lines" do
      expect(log_line["trace_id"]).to eq(trace_id)
    end

    it "includes the request_id on log lines" do
      expect(log_line["request_id"]).to eq(request_id)
    end

    it "includes the request_host on log lines" do
      expect(log_line["request_host"]).to eq("www.example.com")
    end

    it "includes the user_id on log lines" do
      expect(log_line["user_id"]).to eq(standard_user.id)
    end

    it "includes the user_email on log lines" do
      expect(log_line["user_email"]).to eq(standard_user.email)
    end

    it "includes the user_organisation_slug on log lines" do
      expect(log_line["user_organisation_slug"]).to eq(standard_user.organisation.slug)
    end
  end

  context "when the service is in maintenance mode" do
    let(:bypass_ips) { " " }
    let(:expect_response_to_redirect) { true }
    let(:user_ip) { "192.0.0.2" }

    before do
      allow(Settings.maintenance_mode).to receive_messages(enabled: true, bypass_ips:)

      get groups_path, headers: { "HTTP_X_FORWARDED_FOR": user_ip }
      follow_redirect! if expect_response_to_redirect
    end

    it "returns http code 200" do
      expect(response).to have_http_status(:ok)
    end

    it "renders the maintenance page" do
      expect(response).to render_template("errors/maintenance")
    end

    context "when bypass ip range does not cover the user's ip" do
      let(:bypass_ips) { "192.0.0.0/32, 123.123.123.123/32" }

      it "returns http code 200" do
        expect(response).to have_http_status(:ok)
      end

      it "renders the maintenance page" do
        expect(response).to render_template("errors/maintenance")
      end
    end

    context "when the bypass ip range does include the user's ip" do
      let(:bypass_ips) { "192.0.0.0/29, 123.123.123.123/32" }
      let(:expect_response_to_redirect) { false }

      it "returns http code 200" do
        expect(response).to have_http_status(:ok)
      end

      it "renders the root page" do
        expect(response).to render_template("groups/index")
      end
    end
  end

  context "when a user is logged in who does not have access" do
    let(:user) { build :user, :super_admin, has_access: false }

    before do
      login_as user
    end

    [
      "/",
      "/users",
      "/forms/1",
    ].each do |path|
      context "when accessing #{path}" do
        before do
          get path
        end

        it "returns http code 403 for #{path}" do
          expect(response).to have_http_status(:forbidden)
        end

        it "renders the access denied page" do
          expect(response).to render_template("errors/access_denied")
          expect(response.body).to include("if you think this is incorrect.")
        end
      end
    end

    context "when a user is logged in from an access restricting organisation" do
      let(:user) { create :user, email: User::EMAIL_DOMAIN_DENYLIST.first }

      before do
        login_as user
      end

      [
        "/",
        "/users",
        "/forms/1",
      ].each do |path|
        context "when accessing #{path}" do
          before do
            get path
          end

          it "returns http code 403 for #{path}" do
            expect(response).to have_http_status(:forbidden)
          end

          it "renders the access denied by organisation page" do
            expect(response).to render_template("errors/access_denied")
            expect(response.body).to include(I18n.t("forbidden.body_html_org_restricted"))
          end
        end
      end
    end
  end

  context "when a user is logged in who does not have organisation set" do
    let(:user) { create :user, :with_no_org, name: nil }

    before do
      login_as user
    end

    it "redirects to the account organisation page" do
      get root_path
      expect(response).to redirect_to(edit_account_organisation_path)
    end
  end

  describe "act as user" do
    context "when a super admin is acting as another user" do
      let(:actual_user) { super_admin_user }
      let(:acting_as_user) { create :user }

      before do
        allow(Settings).to receive(:act_as_user_enabled).and_return(true)

        login_as_super_admin_user actual_user

        post act_as_user_start_path(acting_as_user.id)
        follow_redirect!
      end

      it "adds the super admin user ID to the session" do
        expect(session["original_user_id"]).to eq actual_user.id
      end

      it "adds the acting as user ID to the session" do
        expect(session["acting_as_user_id"]).to eq acting_as_user.id
      end

      describe "logging", :capture_logging do
        before do
          allow(Lograge).to receive(:logger).and_return(logger)

          get root_path
        end

        it "includes the acting as user id on log lines" do
          expect(log_line["acting_as_user_id"]).to eq(acting_as_user.id)
        end

        it "includes the acting as user email on log lines" do
          expect(log_line["acting_as_user_email"]).to eq(acting_as_user.email)
        end

        it "includes the acting as user organisation_slug on log lines" do
          expect(log_line["acting_as_user_organisation_slug"]).to eq(acting_as_user.organisation.slug)
        end

        it "includes the actual user id on log lines" do
          expect(log_line["user_id"]).to eq(super_admin_user.id)
        end

        it "includes the actual user email on log lines" do
          expect(log_line["user_email"]).to eq(super_admin_user.email)
        end

        it "includes the actual user organisation_slug on log lines" do
          expect(log_line["user_organisation_slug"]).to eq(super_admin_user.organisation.slug)
        end
      end
    end
  end

  describe "#up" do
    it "returns http code 200" do
      get rails_health_check_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "footer" do
    before do
      allow(Settings.forms_product_page).to receive(:url).and_return("https://www.forms.service.gov.uk")

      get root_path
    end

    it "contains the feedback link component" do
      expect(response.body).to include("Help us improve this service")
      expect(response.body).to include("<a href=\"#{I18n.t('feedback_link.feedback_survey_url')}\" class=\"govuk-link\">giving us your feedback</a>")
    end

    it "contains links related to the service" do
      expect(response.body).to include('<a class="govuk-footer__link" href="https://www.forms.service.gov.uk/accessibility">Accessibility statement</a>')
      expect(response.body).to include('<a class="govuk-footer__link" href="https://www.forms.service.gov.uk/cookies">Cookies</a>')
      expect(response.body).to include('<a class="govuk-footer__link" href="https://www.forms.service.gov.uk/privacy">Privacy</a>')
      expect(response.body).to include('<a class="govuk-footer__link" href="https://www.forms.service.gov.uk/terms-of-use">Terms of use</a>')
    end

    it "contains the 'built by' statement" do
      page = Capybara::Node::Simple.new(response.body)

      expect(page).to have_text("Built by the")
      expect(page).to have_link("Government Digital Service", href: "https://www.gov.uk/government/organisations/government-digital-service")
    end
  end
end
