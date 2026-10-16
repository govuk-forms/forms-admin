require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#link_to_runner" do
    context "with no live argument" do
      it "returns url to the form-runner's preview form" do
        expect(helper.link_to_runner("example.com", 2, "garden-form-slug")).to eq "example.com/preview-draft/2/garden-form-slug"
      end
    end

    context "with mode set to preview_draft" do
      it "returns url to the form-runner's preview form" do
        expect(helper.link_to_runner("example.com", 2, "garden-form-slug", mode: :preview_draft)).to eq "example.com/preview-draft/2/garden-form-slug"
      end
    end

    context "with mode set to preview_live" do
      it "returns url to the form-runner's live preview form" do
        expect(helper.link_to_runner("example.com", 2, "garden-form-slug", mode: :preview_live)).to eq "example.com/preview-live/2/garden-form-slug"
      end
    end

    context "with mode set to preview_archived" do
      it "returns url to the form-runner's archived preview form" do
        expect(helper.link_to_runner("example.com", 2, "garden-form-slug", mode: :preview_archived)).to eq "example.com/preview-archived/2/garden-form-slug"
      end
    end

    context "with mode set to live" do
      it "returns url to the form-runner's live form" do
        expect(helper.link_to_runner("example.com", 2, "garden-form-slug", mode: :live)).to eq "example.com/form/2/garden-form-slug"
      end
    end

    context "with no locale provided" do
      it "defaults to the :en locale" do
        expect(helper.link_to_runner("example.com", 2, "garden-form-slug")).to eq "example.com/preview-draft/2/garden-form-slug"
      end
    end

    context "with a locale provided" do
      it "generates a link for the provided locale" do
        expect(helper.link_to_runner("example.com", 2, "garden-form-slug", locale: :cy)).to eq "example.com/preview-draft/2/garden-form-slug.cy"
      end
    end
  end

  describe "#preview_link" do
    let(:form) { Form.new }

    def preview_link(form, mode: :preview_draft, locale: :en)
      link_to_runner(Settings.forms_runner.url, form.id, form.form_slug, mode:, locale:)
    end

    before do
      allow(form).to receive_messages(id: 1, form_slug: "garden-form-slug")
    end

    context "when no mode is provided" do
      it "returns a draft preview link to the form" do
        expect(helper.preview_link(form)).to eq "runner-host/preview-draft/1/garden-form-slug"
      end
    end

    context "when preview_draft mode is provided" do
      it "returns a draft preview link to the form" do
        expect(helper.preview_link(form, mode: :preview_draft)).to eq "runner-host/preview-draft/1/garden-form-slug"
      end
    end

    context "when preview_live mode is provided" do
      it "returns a live preview link to the form" do
        expect(helper.preview_link(form, mode: :preview_live)).to eq "runner-host/preview-live/1/garden-form-slug"
      end
    end

    context "when live mode is provided" do
      it "returns a live link to the form" do
        expect(helper.preview_link(form, mode: :live)).to eq "runner-host/form/1/garden-form-slug"
      end
    end

    context "when no locale is provided" do
      it "returns an English link to the form" do
        expect(helper.preview_link(form)).to eq "runner-host/preview-draft/1/garden-form-slug"
      end
    end

    context "when the English locale is provided" do
      it "returns an English link to the form" do
        expect(helper.preview_link(form, locale: :en)).to eq "runner-host/preview-draft/1/garden-form-slug"
      end
    end

    context "when the Welsh locale is provided" do
      it "returns a Welsh link to the form" do
        expect(helper.preview_link(form, locale: :cy)).to eq "runner-host/preview-draft/1/garden-form-slug.cy"
      end
    end
  end

  describe "contact_url" do
    it "returns a link to contact support" do
      expect(helper.contact_url).to eq t("contact_url")
    end
  end

  describe "contact_link" do
    it "returns a link to contact support with default text" do
      link = <<~HTML
        <a class="govuk-link" href="#{t('contact_url')}">contact the GOV.UK Forms team</a>
      HTML
      link.strip!

      expect(helper.contact_link).to include(link)
    end

    it "returns a link to contact support with custom text" do
      link = <<~HTML
        <a class="govuk-link" href="#{t('contact_url')}">test</a>
      HTML
      link.strip!

      expect(helper.contact_link("test")).to eq link
    end
  end

  describe "question_text_with_optional_suffix" do
    let(:page) { build :page }

    context "when show_optional_suffix? returns true" do
      before do
        allow(page).to receive(:show_optional_suffix?).and_return(true)
      end

      it "returns the title with the optional suffix" do
        expect(helper.question_text_with_optional_suffix(page)).to eq(I18n.t("pages.optional", question_text: page.question_text))
      end
    end

    context "when show_optional_suffix? returns false" do
      before do
        allow(page).to receive(:show_optional_suffix?).and_return(false)
      end

      it "returns the title with the optional suffix" do
        expect(helper.question_text_with_optional_suffix(page)).to eq(page.question_text)
      end
    end
  end

  describe "translation_key_for_answer_type" do
    let(:answer_type) { "email" }
    let(:answer_settings) { {} }

    context "with a non-selection answer type" do
      it "returns the answer type" do
        expect(helper.translation_key_for_answer_type(answer_type, answer_settings)).to eq "email"
      end
    end

    context "with selection answer type" do
      let(:answer_type) { "selection" }

      context "and 'only_one_option' set to 'true'" do
        let(:answer_settings) { OpenStruct.new(only_one_option: "true") }

        it "returns the answer subtype" do
          expect(helper.translation_key_for_answer_type(answer_type, answer_settings)).to eq "radio"
        end
      end

      context "and 'only_one_option' set to 'false'" do
        let(:answer_settings) { OpenStruct.new(only_one_option: false) }

        it "returns the answer subtype" do
          expect(helper.translation_key_for_answer_type(answer_type, answer_settings)).to eq "checkbox"
        end
      end
    end

    context "with text answer type" do
      let(:answer_type) { "text" }
      let(:answer_settings) { OpenStruct.new(input_type:) }

      context "and 'input_type' set to a valid value" do
        let(:input_type) { Pages::TextSettingsInput::INPUT_TYPES.sample }

        it "returns the answer subtype" do
          expect(helper.translation_key_for_answer_type(answer_type, answer_settings)).to eq input_type
        end
      end
    end

    context "with date answer type" do
      let(:answer_type) { "date" }
      let(:answer_settings) { OpenStruct.new(input_type:) }

      context "and 'input_type' set to a valid value" do
        let(:input_type) { Pages::DateSettingsInput::INPUT_TYPES.sample }

        it "returns the answer subtype" do
          expect(helper.translation_key_for_answer_type(answer_type, answer_settings)).to eq input_type
        end
      end
    end
  end

  describe "#hint_for_edit_page_field" do
    context "with an answer type that has custom text" do
      let(:answer_type) { "email" }
      let(:answer_settings) { {} }

      it "returns the custom hint text for the answer type" do
        expect(helper.hint_for_edit_page_field("question_text", answer_type, answer_settings)).to eq(I18n.t("helpers.hint.page.question_text.email"))
      end
    end

    context "with an answer type that does not have custom text" do
      let(:answer_type) { "some_random_string" }
      let(:answer_settings) { {} }

      it "returns the default hint text" do
        expect(helper.hint_for_edit_page_field("hint_text", answer_type, answer_settings)).to eq(I18n.t("helpers.hint.page.hint_text.default"))
      end
    end

    context "with the file answer type" do
      let(:answer_type) { "file" }
      let(:answer_settings) { {} }

      it "returns the hint text for the file answer type" do
        expect(helper.hint_for_edit_page_field("question_text", answer_type, answer_settings)).to eq(I18n.t("helpers.hint.page.question_text.file"))
      end
    end
  end

  describe "#question_text_label" do
    context "with an answer type that does not have custom text" do
      let(:answer_type) { "some_random_string" }
      let(:answer_settings) { {} }

      it "returns the default question text label" do
        expect(helper.question_text_label(answer_type, answer_settings)).to eq(I18n.t("helpers.label.pages_question_input.question_text.default"))
      end
    end

    context "with the file answer type" do
      let(:answer_type) { "file" }
      let(:answer_settings) { {} }

      it "returns the question text label for the file answer type" do
        expect(helper.question_text_label(answer_type, answer_settings)).to eq(I18n.t("helpers.label.pages_question_input.question_text.file"))
      end
    end
  end

  describe "#govuk_assets_path" do
    it "returns the full node_modules asset path" do
      expect(helper.govuk_assets_path).to eq "/node_modules/govuk-frontend/dist/govuk/assets"
    end
  end

  describe "#sign_in_button" do
    context "when user is an e2e user and auth_provider is auth0" do
      before do
        allow(Settings).to receive(:auth_provider).and_return("auth0")
      end

      it "returns a string representing the sign-in button" do
        expect(helper.sign_in_button(is_e2e_user: true)).to include("e2e")
      end

      it "does not include e2e string when not the e2e user" do
        expect(helper.sign_in_button(is_e2e_user: false)).not_to include("e2e")
      end
    end

    context "when auth_provider is not auth0" do
      before do
        allow(Settings).to receive(:auth_provider).and_return("developer")
      end

      it "does not include e2e string when not the e2e user" do
        expect(helper.sign_in_button(is_e2e_user: true)).not_to include("e2e")
      end
    end
  end

  describe "#sign_up_button" do
    context "when user is an e2e user and auth_provider is auth0" do
      before do
        allow(Settings).to receive(:auth_provider).and_return("auth0")
      end

      it "returns a string representing the sign-up button" do
        expect(helper.sign_up_button(is_e2e_user: true)).to include("e2e", "signup")
      end

      context "when user is not an e2e user" do
        it "returns a string representing the sign-up button" do
          expect(helper.sign_up_button(is_e2e_user: false)).not_to include("e2e")
        end
      end
    end

    context "when auth_provider is not auth0" do
      before do
        allow(Settings).to receive(:auth_provider).and_return("developer")
      end

      it "returns a string representing the sign-up button" do
        expect(helper.sign_up_button(is_e2e_user: true)).not_to include("signup")
      end
    end
  end

  describe "omniauth_authorize_path" do
    subject(:omniauth_authorize_path) { helper.omniauth_authorize_path }

    context "when the auth provider is auth0" do
      before do
        allow(Settings).to receive(:auth_provider).and_return("auth0")
      end

      it { is_expected.to eq "/auth/auth0" }
    end

    context "when the auth provider is developer" do
      before do
        allow(Settings).to receive(:auth_provider).and_return("developer")
      end

      it { is_expected.to eq "/auth/developer" }
    end

    context "when the auth provider is user_research" do
      before do
        allow(Settings).to receive(:auth_provider).and_return("user_research")
      end

      it { is_expected.to eq "/auth/user-research" }
    end
  end

  describe "#page_title" do
    context "when no title content is present" do
      it "returns the website name" do
        expect(helper.page_title).to eq "GOV.UK Forms"
      end
    end

    context "when title content is present" do
      let(:title) { Faker::Lorem.sentence(word_count: 1, supplemental: true, random_words_to_add: 5) }

      before do
        helper.content_for(:title, title)
      end

      it "returns the title and website name separated by an en dash" do
        expect(helper.page_title).to eq "#{title}#{I18n.t('page_titles.separator')}GOV.UK Forms"
      end
    end
  end

  describe "#set_page_title" do
    let(:title) { Faker::Lorem.sentence(word_count: 1, supplemental: true, random_words_to_add: 5) }

    it "sets the content_for for the title" do
      allow(helper).to receive(:content_for)

      helper.set_page_title(title)

      expect(helper).to have_received(:content_for).with(:title, title)
    end
  end

  describe "setting and retrieving a page title" do
    context "when the title contains special characters" do
      let(:title) { "#{Faker::Lorem.sentence(word_count: 1, supplemental: true, random_words_to_add: 5)} ‘’&<script>alert('this string contains a script tag')</script>" }

      before do
        helper.set_page_title(title)
      end

      it "escapes the special characters once" do
        expect(helper.page_title).to eq "#{ERB::Util.html_escape(title)}#{I18n.t('page_titles.separator')}GOV.UK Forms"
      end

      it "returns an html safe string" do
        expect(helper.page_title).to be_html_safe
      end
    end

    context "when the title contains a closing title tag" do
      before do
        helper.set_page_title("</title><script>alert(1)</script>")
      end

      it "does not include the unescaped markup" do
        expect(helper.content_for(:title)).to eq "&lt;/title&gt;&lt;script&gt;alert(1)&lt;/script&gt;"
      end
    end
  end

  describe "#acting_as?" do
    it "returns true when the signed in user is acting as another" do
      session[:acting_as_user_id] = 1

      expect(helper.acting_as?).to be true
    end

    it "returns false when the signed in user is not acting as another" do
      session.delete :acting_as_user_id

      expect(helper.acting_as?).to be false
    end
  end

  describe "#actual_user?" do
    it "returns the original user when the signed in user is acting as another" do
      user = create :user
      session[:acting_as_user_id] = 1
      session[:original_user_id] = user.id

      expect(helper.actual_user).to eq user
    end

    it "returns nil when the signed in user is not acting as another" do
      session.delete :acting_as_user_id
      session.delete :original_user_id

      expect(helper.actual_user).to be_nil
    end
  end

  describe "#acting_as_user?" do
    it "returns the acting as user when the signed in user is acting as another" do
      user = create :user
      session[:acting_as_user_id] = user.id
      request.env["warden"] = OpenStruct.new(user:)

      expect(helper.acting_as_user).to be user
    end

    it "returns nil when the signed in user is not acting as another" do
      session.delete :acting_as_user_id

      expect(helper.acting_as_user).to be_nil
    end
  end

  describe "#date_last_signed_in_at" do
    subject(:date_last_signed_in_at) { helper.date_last_signed_in_at(user) }

    let(:user) { build :user, last_signed_in_at:, provider: }
    let(:provider) { nil }

    context "when user has signed in since last_signed_in_at code was added" do
      let(:last_signed_in_at) { Time.zone.iso8601 "2024-11-04T15:45:00" }

      it "renders the date" do
        expect(date_last_signed_in_at).to eq("4 November 2024")
      end
    end

    context "when user has signed in since Auth0 was enabled but not since last_signed_in_at code was added" do
      let(:provider) { :auth0 }
      let(:last_signed_in_at) { nil }

      it "renders text explaining that we don't know when exact time, but that it was more recent than since Auth0 being enabled" do
        expect(date_last_signed_in_at).to eq "Sometime between 3 November 2023 and 4 November 2024"
      end
    end

    context "when user has not signed in since Auth0 was enabled" do
      let(:provider) { :gds }
      let(:last_signed_in_at) { nil }

      it "renders text explaining that we don't know exact time, but that it was less recent than Auth0 being enabled" do
        expect(date_last_signed_in_at).to eq "Before 3 November 2023"
      end
    end
  end
end
