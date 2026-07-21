require "rails_helper"

RSpec.describe Forms::BatchSubmissionsController, type: :request do
  let(:form) { create(:form, :live) }
  let(:current_user) { standard_user }
  let(:group) { create(:group, organisation: standard_user.organisation) }

  before do
    Membership.create!(group_id: group.id, user: standard_user, added_by: standard_user)
    GroupForm.create!(form_id: form.id, group_id: group.id)

    login_as current_user
  end

  describe "#new" do
    before do
      get batch_submissions_path(form_id: form.id)
    end

    it "renders the daily submission batch view" do
      expect(response).to have_rendered :new
    end

    it "uses the daily submission batch input" do
      expect(assigns).to include batch_submissions_input: an_instance_of(Forms::BatchSubmissionsInput)
    end

    context "when the user is not authorized" do
      let(:current_user) { build :user }

      it "returns 403" do
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "#create" do
    let(:params) { { forms_batch_submissions_input: { batch_frequencies: } } }
    let(:batch_frequencies) { %w[daily weekly] }

    before do
      post(batch_submissions_create_path(form_id: form.id), params:)
    end

    it "updates the form" do
      expect(form.reload.delivery_configurations.pluck(:delivery_method, :delivery_schedule, :formats)).to contain_exactly(
        ["email", "daily", %w[csv]],
        ["email", "weekly", %w[csv]],
      )
    end

    it "redirects to the form overview page" do
      expect(response).to redirect_to(form_path(form.id))
    end

    context "when only the daily batch checkbox is checked" do
      let(:batch_frequencies) { %w[daily] }

      it "displays a success flash message indicating that daily batch emails are enabled" do
        expect(flash[:success]).to eq(I18n.t("banner.success.form.batch_submissions.daily_enabled"))
      end
    end

    context "when only the weekly batch checkbox is checked" do
      let(:batch_frequencies) { %w[weekly] }

      it "displays a success flash message indicating that weekly batch emails are enabled" do
        expect(flash[:success]).to eq(I18n.t("banner.success.form.batch_submissions.weekly_enabled"))
      end
    end

    context "when both the daily and weekly batch checkboxes are checked" do
      let(:batch_frequencies) { %w[daily weekly] }

      it "displays a success flash message indicating that daily and weekly batch emails are enabled" do
        expect(flash[:success]).to eq(I18n.t("banner.success.form.batch_submissions.daily_and_weekly_enabled"))
      end
    end

    context "when daily and weekly batch checkboxes are unchecked" do
      let(:form) do
        create(:form, :live, delivery_configurations: [
          create(:delivery_configuration, :daily_email),
          create(:delivery_configuration, :weekly_email),
        ])
      end
      let(:batch_frequencies) { [] }

      it "displays a success flash message indicating that batch emails are disabled" do
        expect(flash[:success]).to eq(I18n.t("banner.success.form.batch_submissions.disabled"))
      end
    end

    context "when the delivery configurations are unchanged" do
      let(:form) do
        create(:form, :live, delivery_configurations: [
          create(:delivery_configuration, :daily_email),
        ])
      end
      let(:batch_frequencies) { %w[daily] }

      it "does not display a flash message" do
        expect(flash[:success]).to be_nil
      end
    end

    context "when the user is not authorized" do
      let(:current_user) { build :user }

      it "returns 403" do
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
