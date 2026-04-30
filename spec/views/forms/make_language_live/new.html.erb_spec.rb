require "rails_helper"

describe "forms/make_language_live/new.html.erb" do
  let(:current_form) { OpenStruct.new(id: 1, name: "Form 1", form_slug: "form-1", submission_email: "example@example.gov.uk") }
  let(:make_language_live_input) { Forms::MakeLiveInput.new(form: current_form) }
  let(:language) { "en" }

  before do
    assign(:make_language_live_input, make_language_live_input)

    without_partial_double_verification do
      allow(view).to receive_messages(form_path: "/forms/1", make_language_live_create_path: "forms/1/make-live/#{language}")
    end
  end

  context "when there are no errors" do
    before do
      render template: "forms/make_language_live/new", locals: { current_form:, language: }
    end

    context "when the language being made live is English" do
      let(:language) { "en" }

      it "has the correct page title" do
        expect(view.content_for(:title)).to eq t("page_titles.make_language_live.en")
      end

      it "contains a heading" do
        expect(rendered).to have_css("h1", text: t("page_titles.make_language_live.en"))
      end

      it "contains the body text" do
        expect(rendered).to include(t("make_language_live.en.new.body_html", submission_email: current_form.submission_email))
      end

      it "renders radio buttons for making the draft changes live" do
        expect(rendered).to have_css("legend", text: I18n.t("helpers.label.forms_make_language_live_input.en.confirm"))
        expect(rendered).to have_field("Yes", type: "radio")
        expect(rendered).to have_field("No", type: "radio")
      end

      it "renders a submit button" do
        expect(rendered).to have_css("button", text: I18n.t("save_and_continue"))
      end
    end

    context "when the language being made live is Welsh" do
      let(:language) { "cy" }

      it "has the correct page title" do
        expect(view.content_for(:title)).to eq t("page_titles.make_language_live.cy")
      end

      it "contains a heading" do
        expect(rendered).to have_css("h1", text: t("page_titles.make_language_live.cy"))
      end

      it "contains the body text" do
        expect(rendered).to include(t("make_language_live.cy.new.body_html", submission_email: current_form.submission_email))
      end

      it "renders radio buttons for making the draft changes live" do
        expect(rendered).to have_css("legend", text: I18n.t("helpers.label.forms_make_language_live_input.cy.confirm"))
        expect(rendered).to have_field("Yes", type: "radio")
        expect(rendered).to have_field("No", type: "radio")
      end

      it "renders a submit button" do
        expect(rendered).to have_css("button", text: I18n.t("save_and_continue"))
      end
    end
  end

  context "when there are errors" do
    before do
      make_language_live_input.errors.add(:confirm, "An error")

      assign(:make_language_live_input, make_language_live_input)
      render template: "forms/make_language_live/new", locals: { current_form:, language: }
    end

    context "when the language being made live is English" do
      let(:language) { "en" }

      it "displays the error summary" do
        expect(rendered).to have_selector(".govuk-error-summary")
      end

      it "displays an inline error message" do
        expect(rendered).to have_css(".govuk-error-message")
      end

      it "sets the page title with error prefix" do
        expect(view.content_for(:title)).to eq(title_with_error_prefix(t("page_titles.make_language_live.en"), true))
      end
    end

    context "when the language being made live is Welsh" do
      let(:language) { "cy" }

      it "displays the error summary" do
        expect(rendered).to have_selector(".govuk-error-summary")
      end

      it "displays an inline error message" do
        expect(rendered).to have_css(".govuk-error-message")
      end

      it "sets the page title with error prefix" do
        expect(view.content_for(:title)).to eq(title_with_error_prefix(t("page_titles.make_language_live.cy"), true))
      end
    end
  end
end
