require "rails_helper"

RSpec.describe Forms::WelshTranslationController, type: :request do
  let(:form) { create(:form, :ready_for_routing, welsh_completed: false) }
  let(:id) { form.id }
  let(:condition) { create :condition, routing_page: form.pages.first, answer_value: "No", exit_page_heading: "You are ineligible", exit_page_markdown: "Sorry, you are ineligible for this service." }

  let(:current_user) { standard_user }
  let(:group) { create(:group, organisation: standard_user.organisation) }

  before do
    Membership.create!(group_id: group.id, user: standard_user, added_by: standard_user)
    GroupForm.create!(form_id: form.id, group_id: group.id)

    login_as current_user
  end

  describe "#new" do
    before do
      get welsh_translation_path(id)
    end

    it "renders the template" do
      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:new)
    end

    context "when the user is not authorized" do
      let(:current_user) { build :user }

      it "returns 403" do
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "#create" do
    let(:mark_complete) { "true" }
    let(:condition_translations_attributes) { { "0" => { "id" => condition.id, exit_page_heading_cy: "Nid ydych yn gymwys", exit_page_markdown_cy: "Mae'n ddrwg gennym, nid ydych yn gymwys ar gyfer y gwasanaeth hwn." } } }
    let(:page_translations_attributes) { { "0" => { "id" => form.pages.first.id, question_text_cy: "Ydych chi'n adnewyddu trwydded?", condition_translations_attributes: } } }
    let(:params) { { forms_welsh_translation_input: { form:, mark_complete:, name_cy: "Gwneud cais am drwydded jyglo", privacy_policy_url_cy: "https://juggling.gov.uk/privacy_policy/cy", page_translations_attributes: } } }

    context "when 'Yes' is selected" do
      it "updates the form, pages and conditions" do
        expect {
          post(welsh_translation_create_path(id), params:)
        }.to change { form.reload.welsh_completed }.to(true)
        .and change { form.pages.first.reload.question_text_cy }.to("Ydych chi'n adnewyddu trwydded?")
        .and change { condition.reload.exit_page_heading_cy }.to("Nid ydych yn gymwys")
      end

      it "redirects to the form task list and displays a success banner including text about being marked complete" do
        post(welsh_translation_create_path(id), params:)
        expect(response).to redirect_to(form_path(id))
        expect(flash[:success]).to eq(I18n.t("banner.success.form.welsh_translation_saved_and_completed"))
      end
    end

    context "when 'No' is selected" do
      let(:mark_complete) { "false" }
      let(:form) { create(:form, :ready_for_routing, welsh_completed: true) }

      it "updates the form and redirects to the form task list" do
        expect {
          post(welsh_translation_create_path(id), params:)
        }.to change { form.reload.welsh_completed }.to(false)
      end

      it "redirects to the form and displays a success banner without text about being marked complete" do
        post(welsh_translation_create_path(id), params:)
        expect(response).to redirect_to(form_path(id))
        expect(flash[:success]).to eq(I18n.t("banner.success.form.welsh_translation_saved"))
      end
    end

    context "when no value is selected" do
      let(:mark_complete) { "" }

      it "does not update the form, pages or conditions" do
        expect {
          post(welsh_translation_create_path(id), params:)
        }.to not_change { form.reload.welsh_completed }
        .and not_change { form.pages.first.reload.question_text_cy }
        .and(not_change { condition.reload.exit_page_markdown_cy })
      end

      it "returns a 422, re-renders the page with an error, and does not display a success banner" do
        post(welsh_translation_create_path(id), params:)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response).to render_template(:new)
        expect(response.body).to include(I18n.t("activemodel.errors.models.forms/welsh_translation_input.attributes.mark_complete.blank"))
        expect(flash).to be_empty
      end
    end

    context "when 'Yes' is selected and all fields are empty" do
      let(:condition_translations_attributes) { { "0" => { "id" => condition.id, exit_page_heading_cy: "", exit_page_markdown_cy: "" } } }
      let(:page_translations_attributes) { { "0" => { "id" => form.pages.first.id, question_text_cy: "", condition_translations_attributes: } } }
      let(:params) { { forms_welsh_translation_input: { form:, mark_complete:, name_cy: "", privacy_policy_url_cy: "", page_translations_attributes: } } }

      it "deletes the form" do
        post(welsh_translation_create_path(id), params:)
        expect(form.pages.first.reload.question_text_cy).to be_nil
        expect(condition.reload.exit_page_heading_cy).to be_nil
      end

      it "redirects to the form with a success banner" do
        post(welsh_translation_create_path(id), params:)
        expect(response).to redirect_to(form_path(id))
        expect(flash[:success]).to eq(I18n.t("forms.welsh_translation.destroy.success"))
      end
    end

    context "when 'Yes' is selected and support email does not end in '.gov.uk'" do
      let(:domain) { "ogd.ewxample" }
      let(:support_email) { Faker::Internet.email(domain:) }

      let(:form) { create(:form, :ready_for_routing, welsh_completed: false, support_email:) }
      let(:params) { { forms_welsh_translation_input: { form:, mark_complete:, name_cy: "Gwneud cais am drwydded jyglo", privacy_policy_url_cy: "https://juggling.gov.uk/privacy_policy/cy", support_email_cy: support_email, page_translations_attributes: } } }

      it "returns a 422, re-renders the page with an error, and does not display a success banner" do
        post(welsh_translation_create_path(id), params:)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response).to render_template(:new)
        expect(response.body).to include(I18n.t("activemodel.errors.models.forms/welsh_translation_input.attributes.support_email_cy.non_government_email"))
        expect(flash).to be_empty
      end

      context "and the current user is signed in with an email address at the same domain" do
        let(:standard_user) { build :user, :standard, organisation: test_org, email: Faker::Internet.email(domain:) }

        it "redirects to the form task list and displays a success banner including text about being marked complete" do
          post(welsh_translation_create_path(id), params:)
          expect(response).to redirect_to(form_path(id))
          expect(flash[:success]).to eq(I18n.t("banner.success.form.welsh_translation_saved_and_completed"))
        end
      end
    end

    context "when the user is not authorized" do
      let(:current_user) { build :user }

      it "does not update the form, pages or conditions" do
        expect {
          post(welsh_translation_create_path(id), params:)
        }.to not_change { form.reload.welsh_completed }
        .and not_change { form.pages.first.reload.question_text_cy }
        .and(not_change { condition.reload.exit_page_markdown_cy })
      end

      it "returns 403" do
        post(welsh_translation_create_path(id), params:)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "#delete" do
    before do
      get welsh_translation_delete_path(id)
    end

    it "renders the template" do
      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:delete)
    end

    context "when the user is not authorized" do
      let(:current_user) { build :user }

      it "returns 403" do
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "#destroy" do
    let(:form) { create(:form, :with_welsh_translation) }
    let(:confirm) { "yes" }
    let(:params) { { forms_delete_welsh_translation_input: { form:, confirm: } } }

    context "when 'Yes' is selected" do
      it "removes the Welsh content from the form" do
        expect {
          delete(welsh_translation_destroy_path(id), params:)
        }.to change { form.reload.name_cy }.to(nil)
      end

      it "redirects to the form with a success banner" do
        delete(welsh_translation_destroy_path(id), params:)
        expect(response).to redirect_to(form_path(id))
        expect(flash[:success]).to eq(I18n.t("forms.welsh_translation.destroy.success"))
      end
    end

    context "when 'No' is selected" do
      let(:confirm) { "no" }

      it "does not change the form" do
        expect {
          delete(welsh_translation_destroy_path(id), params:)
        }.not_to(change(form, :reload))
      end

      it "redirects back to the Welsh version page" do
        delete(welsh_translation_destroy_path(id), params:)
        expect(response).to redirect_to(welsh_translation_path(id))
      end
    end

    context "when no value is selected" do
      let(:confirm) { nil }

      it "does not change the form" do
        expect {
          delete(welsh_translation_destroy_path(id), params:)
        }.not_to(change(form, :reload))
      end

      it "re-renders the page with an error and a 422 response" do
        delete(welsh_translation_destroy_path(id), params:)
        expect(response).to have_http_status(:unprocessable_content)
        expect(response).to render_template(:delete)
        expect(response.body).to include(I18n.t("activemodel.errors.models.forms/delete_welsh_translation_input.attributes.confirm.blank"))
        expect(flash).to be_empty
      end
    end

    context "when the user is not authorized" do
      let(:current_user) { build :user }

      it "does not change the form" do
        expect {
          delete(welsh_translation_destroy_path(id), params:)
        }.not_to(change(form, :reload))
      end

      it "returns 403" do
        delete(welsh_translation_destroy_path(id), params:)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "#render_preview" do
    let(:markdown) { "[Markdown](https://example.com)" }

    before do
      post welsh_translation_render_preview_path(form_id: form.id), params: { markdown: }
    end

    it "returns a JSON object containing the converted HTML" do
      expect(response).to have_http_status(:ok)
      expect(response.body).to eq({
        preview_html: "<p class=\"govuk-body\"><a href=\"https://example.com\" class=\"govuk-link\" rel=\"noreferrer noopener\" target=\"_blank\">Markdown (agor mewn tab newydd)</a></p>",
        errors: [],
      }.to_json)
    end

    context "when markdown is blank" do
      let(:markdown) { "" }

      it "returns a JSON object containing the converted HTML" do
        expect(response).to have_http_status(:ok)
        expect(response.body).to eq({ preview_html: I18n.t("markdown_editor.no_markdown_content_html"), errors: [] }.to_json)
      end
    end
  end

  describe "#download" do
    let(:form) { create(:form, :with_welsh_translation, name: "A form with Welsh") }

    before do
      get welsh_translation_download_path(id)
    end

    context "when the user is not authorized" do
      let(:current_user) { build :user }

      it "returns 403" do
        expect(response).to have_http_status(:forbidden)
      end
    end

    it "downloads a CSV file" do
      expect(response).to have_http_status(:ok)
      expect(response.headers["content-type"]).to eq "text/csv; charset=iso-8859-1"
      expect(response.headers["content-disposition"]).to match("attachment; filename=a_form_with_welsh.csv")
    end

    it "returns a CSV with a header row and and content" do
      csv = CSV.parse(response.body)

      expect(csv.first).to eq(["Identifier (do not change)", "Content", "English content", "Welsh content"])
      expect(csv.second).to eq(["name", "Form name", "A form with Welsh", "Welsh A form with Welsh"])
    end
  end

  describe "#upload" do
    let(:form) { create(:form, :ready_for_routing, welsh_completed: false) }

    let(:csv_data) do
      CSV.generate do |csv|
        csv << [WelshSpreadsheetImportService::ID_COLUMN, "Content", "English content", "Welsh content"]
        csv << ["name", "Form name", form.name, "Fy Ffurflen"]
      end
    end

    let(:file) do
      file = Tempfile.new(["translations", ".csv"])
      file.write(csv_data)
      file.rewind
      Rack::Test::UploadedFile.new(file.path, "text/csv", original_filename: "translations.csv")
    end

    context "when a valid CSV is uploaded" do
      before do
        post welsh_translation_upload_path(id), params: { forms_welsh_translation_upload_input: { file: } }
      end

      it "renders the new template" do
        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:new)
      end

      it "pre-populates form name from CSV" do
        expect(response.body).to include("Fy Ffurflen")
      end
    end

    context "when no file is provided" do
      before do
        post welsh_translation_upload_path(id), params: { forms_welsh_translation_upload_input: { file: nil } }
      end

      it "renders the upload file page with an error" do
        expect(response).to have_http_status(:unprocessable_content)
        expect(response).to render_template(:show_upload)
        expect(response.body).to include(I18n.t("activemodel.errors.models.forms/welsh_translation_upload_input.attributes.file.blank"))
        expect(flash).to be_empty
      end
    end

    context "when the user is not authorized" do
      let(:current_user) { build :user }

      before do
        post welsh_translation_upload_path(id), params: { file: }
      end

      it "returns 403" do
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
