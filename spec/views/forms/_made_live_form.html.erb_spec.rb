require "rails_helper"

describe "forms/_made_live_form.html.erb" do
  let(:declaration_markdown) { Faker::Lorem.paragraph(sentence_count: 2, supplemental: true, random_sentences_to_add: 4) }
  let(:past_week_metrics_data) { { weekly_submissions: 125, weekly_starts: 256 } }
  let(:what_happens_next_markdown) { "If you have not received a response within 5 working days, [contact our user support team](https://example.com)." }
  let(:form_metadata) do
    create(:form, :live, declaration_markdown:, what_happens_next_markdown:, submission_type:, submission_format:,
                         send_daily_submission_batch:, send_weekly_submission_batch:)
  end
  let(:form_document) do
    form_document_content = FormDocument::Content.from_form_document(form_metadata.live_form_document)
    form_document_content.first_made_live_at = 1.week.ago
    form_document_content
  end
  let(:welsh_form_document) { nil }
  let(:group) { create(:group, name: "Group 1") }
  let(:status) { :live }
  let(:preview_mode) { :preview_live }
  let(:questions_path) { Faker::Internet.url }
  let(:submission_type) { "email" }
  let(:submission_format) { [] }
  let(:send_daily_submission_batch) { false }
  let(:send_weekly_submission_batch) { false }
  let(:cloudwatch_service) { instance_double(CloudWatchService, past_week_metrics_data:) }

  before do
    allow(CloudWatchService).to receive(:new).and_return(cloudwatch_service)

    if group.present?
      GroupForm.create!(form_id: form_document.id, group_id: group.id)
    end

    render(partial: "forms/made_live_form", locals: {
      form_metadata:,
      form_document:,
      welsh_form_document:,
      status:,
      preview_mode:,
      questions_path:,
    })
  end

  it "has the correct title" do
    expect(view.content_for(:title)).to have_content(form_document.name.to_s)
  end

  it "back link is set to group page" do
    expect(view.content_for(:back_link)).to have_link("Back to Group 1", href: group_path(group))
  end

  it "contains page heading" do
    expect(rendered).to have_css("h1.govuk-heading-xl", text: form_document.name)
  end

  describe "form status tag" do
    context "when the form is live" do
      it "renders the live tag" do
        expect(rendered).to have_css(".govuk-tag.govuk-tag--teal", text: "Live")
      end
    end

    context "when the form is archived" do
      let(:status) { :archived }

      it "renders the archived tag" do
        expect(rendered).to have_css(".govuk-tag.govuk-tag--orange", text: "Archived")
      end
    end
  end

  describe "the link to the preview form" do
    context "when the form is live" do
      it "contains a link to preview the form" do
        expect(rendered).to have_link(t("home.preview"), href: "runner-host/preview-live/#{form_document.id}/#{form_document.form_slug}", visible: :all)
      end
    end

    context "when the form is archived" do
      let(:preview_mode) { :preview_archived }

      it "contains a link to preview the archived form" do
        expect(rendered).to have_link(t("home.preview"), href: "runner-host/preview-archived/#{form_document.id}/#{form_document.form_slug}", visible: :all)
      end
    end
  end

  describe "the link to the live form" do
    context "when the form is live" do
      it "contains the title 'Form URL'" do
        expect(rendered).to have_css("h3", text: "Form URL")
      end

      it "contains a link to the form in the runner" do
        expect(rendered).to have_css("[data-copy-target]", text: "runner-host/form/#{form_document.id}/#{form_document.form_slug}")
      end
    end

    context "when the form is archived" do
      let(:status) { :archived }

      it "contains the title 'Previous form URL'" do
        expect(rendered).to have_css("h3", text: "Previous form URL")
      end

      it "contains a link to the form in the runner" do
        expect(rendered).to have_css("[data-copy-target]", text: "runner-host/form/#{form_document.id}/#{form_document.form_slug}")
      end
    end
  end

  it "contains a link to view questions" do
    expect(rendered).to have_link("#{form_document.steps.count} questions", href: questions_path)
  end

  context "with only a single question" do
    let(:form_metadata) { create :form, :live, pages_count: 1 }

    it "contains a link to view questions with correct pluralization" do
      expect(rendered).to have_link("1 question", href: questions_path)
    end
  end

  it "contains declaration" do
    expect(rendered).to have_css("h3", text: "Declaration")
    expect(rendered).to have_content(declaration_markdown)
  end

  context "with no declaration set" do
    let(:declaration_markdown) { nil }

    it "does not include declaration" do
      expect(rendered).not_to have_css("h3", text: "Declaration")
    end
  end

  it "contains what happens next text" do
    expect(rendered).to include("<p class=\"govuk-body\">If you have not received a response within 5 working days, <a href=\"https://example.com\" class=\"govuk-link\" rel=\"noreferrer noopener\" target=\"_blank\">contact our user support team (opens in new tab)</a>.</p>")
  end

  it "contains information about how you get completed forms" do
    expect(rendered).to have_css("h3", text: I18n.t("forms.made_live_form.how_you_get_completed_forms.title"))
    expect(rendered).to have_xpath("//h3[text()='#{I18n.t('forms.made_live_form.how_you_get_completed_forms.title')}']/following-sibling::h4", text: "Email")
    expect(rendered).to have_text(form_document.submission_email)
  end

  context "when the submission type is 'email'" do
    context "when CSV submission is enabled" do
      let(:submission_format) { %w[csv] }

      it "tells the user they have CSVs enabled" do
        expect(rendered).to have_css("h4", text: I18n.t("forms.made_live_form.how_you_get_completed_forms.csv_and_json"))
        expect(rendered).to include(I18n.t("forms.made_live_form.how_you_get_completed_forms.submission_format.email.email_csv_html"))
      end
    end

    context "when JSON submission is enabled" do
      let(:submission_format) { %w[json] }

      it "tells the user they have JSON submissions enabled" do
        expect(rendered).to have_css("h4", text: I18n.t("forms.made_live_form.how_you_get_completed_forms.csv_and_json"))
        expect(rendered).to include(I18n.t("forms.made_live_form.how_you_get_completed_forms.submission_format.email.email_json_html"))
      end
    end

    context "when both CSV and JSON submissions are enabled" do
      let(:submission_format) { %w[csv json] }

      it "tells the user they have CSV and JSON submissions enabled" do
        expect(rendered).to have_css("h4", text: I18n.t("forms.made_live_form.how_you_get_completed_forms.csv_and_json"))
        expect(rendered).to include(I18n.t("forms.made_live_form.how_you_get_completed_forms.submission_format.email.email_csv_json_html"))
      end
    end

    context "when CSV submission is not enabled" do
      let(:submission_format) { %w[] }

      it "tells the user they do not have CSVs enabled" do
        expect(rendered).to have_css("h4", text: I18n.t("forms.made_live_form.how_you_get_completed_forms.csv_and_json"))
        expect(rendered).to include(I18n.t("forms.made_live_form.how_you_get_completed_forms.submission_format.email.email_html"))
      end
    end
  end

  context "when the submission type is 's3'" do
    let(:submission_type) { "s3" }

    it "does not include the CSV and JSON section" do
      expect(rendered).not_to have_css("h4", text: I18n.t("forms.made_live_form.how_you_get_completed_forms.csv_and_json"))
    end
  end

  it "has a section for daily and weekly CSVs" do
    expect(rendered).to have_css("h4", text: I18n.t("forms.made_live_form.how_you_get_completed_forms.batch_submissions.title"))
  end

  context "when only daily batches are enabled" do
    let(:send_daily_submission_batch) { true }

    it "tells the user they getting a daily CSV" do
      expect(rendered).to include(I18n.t("forms.made_live_form.how_you_get_completed_forms.batch_submissions.daily_enabled"))
    end
  end

  context "when only weekly batches are enabled" do
    let(:send_weekly_submission_batch) { true }

    it "tells the user they getting a weekly CSV" do
      expect(rendered).to include(I18n.t("forms.made_live_form.how_you_get_completed_forms.batch_submissions.weekly_enabled"))
    end
  end

  context "when both daily and weekly batches are enabled" do
    let(:send_daily_submission_batch) { true }
    let(:send_weekly_submission_batch) { true }

    it "tells the user they getting a daily and weekly CSV" do
      expect(rendered).to include(I18n.t("forms.made_live_form.how_you_get_completed_forms.batch_submissions.daily_and_weekly_enabled"))
    end
  end

  context "when neither daily or weekly batches are enabled" do
    let(:send_daily_submission_batch) { false }
    let(:send_weekly_submission_batch) { false }

    it "tells the user they have not opted to get a daily or weekly CSV" do
      expect(rendered).to include(I18n.t("forms.made_live_form.how_you_get_completed_forms.batch_submissions.disabled"))
    end
  end

  it "contains link to privacy policy" do
    expect(rendered).to have_link(form_document.privacy_policy_url, href: form_document.privacy_policy_url)
  end

  context "with a support email address" do
    let(:form_metadata) { create :form, :live, support_email: "support@example.gov.uk" }

    it "shows the support email address" do
      expect(rendered).to have_xpath("//h3[text()='#{I18n.t('forms.made_live_form.contact_details')}']/following-sibling::h4", text: "Email")
      expect(rendered).to have_content("support@example.gov.uk")
    end
  end

  context "with a support phone" do
    let(:form_metadata) { create :form, :live, support_phone: "phone details" }

    it "shows the support phone number" do
      expect(rendered).to have_css("h4", text: "Phone")
      expect(rendered).to have_content("phone details")
    end
  end

  context "with a support online" do
    let(:form_metadata) { create :form, :live, support_url_text: "website", support_url: "www.example.gov.uk" }

    it "shows the support contact online" do
      expect(rendered).to have_css("h4", text: "Support contact online")
      expect(rendered).to have_link(form_document.support_url_text, href: form_document.support_url)
    end
  end

  context "with no support information set" do
    let(:form_document) do
      form_document_content = FormDocument::Content.from_form_document(form_metadata.live_form_document)
      form_document_content.support_email = nil
      form_document_content.support_url_text = nil
      form_document_content.support_url = nil
      form_document_content.support_phone = nil
      form_document_content
    end

    it "does not include support details if they are not set" do
      expect(rendered).not_to have_xpath("//h3[text()='#{I18n.t('made_live_form.contact_details')}']/following-sibling::h4", text: "Email")
      expect(rendered).not_to have_css("h4", text: "Phone")
      expect(rendered).not_to have_css("h4", text: "Support contact online")
    end
  end

  it "contains a link to create a new draft" do
    expect(rendered).to have_link("Create a draft to edit", href: form_path(form_document.id))
  end

  context "when form has a draft version already" do
    let(:form_metadata) { create :form, :live_with_draft }

    it "contains a link to edit the draft" do
      expect(rendered).to have_link("Edit the draft of this form", href: form_path(form_document.id))
    end
  end

  describe "the archive this form button" do
    context "when the form is live" do
      it "contains a link to archive the form" do
        expect(rendered).to have_link("Archive this form")
      end
    end

    context "when the form is archived" do
      let(:status) { :archived }

      it "does not contain a link to archive the form" do
        expect(rendered).not_to have_link("Archive this form")
      end
    end
  end

  describe "the make a copy of this form button" do
    context "when the form is live with no draft" do
      it "contains a link to make a copy of the form" do
        expect(rendered).to have_link("Make a copy of this form")
      end

      it "includes the live tag in the path" do
        expect(rendered).to have_link("Make a copy of this form", href: %r{/copy/live})
      end
    end

    context "when the form is live with a draft" do
      let(:form_metadata) { create :form, :live_with_draft }

      it "contains a link to make a copy of the form" do
        expect(rendered).to have_link("Make a copy of this form")
      end

      it "includes the live tag in the path" do
        expect(rendered).to have_link("Make a copy of this form", href: %r{/copy/live})
      end
    end

    context "when the form is archived with no draft" do
      let(:status) { :archived }
      let(:form_metadata) { create :form, :archived }
      let(:form_document) do
        form_document_content = FormDocument::Content.from_form_document(form_metadata.archived_form_document)
        form_document_content.live_at = 1.week.ago
        form_document_content
      end

      it "contains a link to make a copy of the form" do
        expect(rendered).to have_link("Make a copy of this form")
      end

      it "includes the archived tag in the path" do
        expect(rendered).to have_link("Make a copy of this form", href: %r{/copy/archived})
      end
    end

    context "when the form is archived with a draft" do
      let(:status) { :archived }
      let(:form_metadata) { create :form, :archived_with_draft }
      let(:form_document) do
        form_document_content = FormDocument::Content.from_form_document(form_metadata.archived_form_document)
        form_document_content.live_at = 1.week.ago
        form_document_content
      end

      it "contains a link to make a copy of the form" do
        expect(rendered).to have_link("Make a copy of this form")
      end

      it "includes the archived tag in the path" do
        expect(rendered).to have_link("Make a copy of this form", href: %r{/copy/archived})
      end
    end
  end

  describe "the archive welsh button" do
    it "template does not contain a link to archive the welsh version of the form" do
      expect(rendered).not_to have_link("Archive the Welsh version of this form", href: archive_welsh_path(form_document.id))
    end

    context "when the form is live and the form has a welsh translation" do
      let(:form_metadata) { create :form, :live, :with_welsh_translation }
      let(:welsh_form_document) do
        FormDocument::Content.from_form_document(form_metadata.live_welsh_form_document)
      end

      it "template contains a link to archive the welsh version of the form" do
        expect(rendered).to have_link("Archive the Welsh version of this form", href: archive_welsh_path(form_document.id))
      end
    end
  end

  it "renders the metrics summary component" do
    expect(rendered).to have_text("Form metrics for the past 7 days")
  end

  context "when form is not in a group" do
    let(:group) { nil }

    it "back link is set to root" do
      expect(view.content_for(:back_link)).to have_link("Back to your forms", href: "/")
    end
  end

  context "when the form has a payment link" do
    let(:payment_url) { "https://www.gov.uk/payments/your-payment-link" }
    let(:form_metadata) { create :form, :live, payment_url: }

    it "contains a link to the payment url" do
      expect(rendered).to have_css("h3", text: "GOV.UK Pay payment link")
      expect(rendered).to have_link(payment_url, href: payment_url)
    end
  end

  context "when the form has a Welsh translation" do
    let(:what_happens_next_markdown_cy) { "Os nad ydych wedi derbyn ymateb o fewn 5 diwrnod gwaith, [cysylltwch â’n tîm cymorth defnyddwyr](https://example.com)." }
    let(:form_metadata) { create :form, :live, :with_welsh_translation, what_happens_next_markdown:, what_happens_next_markdown_cy:, submission_type:, submission_format: }
    let(:welsh_form_document) do
      form_document_content = FormDocument::Content.from_form_document(form_metadata.live_welsh_form_document)
      form_document_content.first_made_live_at = 1.week.ago
      form_document_content
    end

    it "includes the Welsh name of the form" do
      expect(rendered).to have_css("h3", text: "Welsh form name")
      expect(rendered).to have_text(welsh_form_document.name)
    end

    it "includes a link to preview the English version" do
      expect(rendered).to have_link("English", href: "runner-host/preview-live/#{form_document.id}/#{form_document.form_slug}", visible: :all)
    end

    it "includes a link to preview the Welsh version" do
      expect(rendered).to have_link("Preview this form in Welsh", href: "runner-host/preview-live/#{form_document.id}/#{form_document.form_slug}.cy", visible: :all)
    end

    it "contains the English form URL" do
      expect(rendered).to have_css("h3", text: "English form URL")
      expect(rendered).to have_text(link_to_runner(Settings.forms_runner.url, form_document.id, form_document.form_slug, mode: :live))
    end

    it "contains the Welsh form URL" do
      expect(rendered).to have_css("h3", text: "Welsh form URL")
      expect(rendered).to have_text(link_to_runner(Settings.forms_runner.url, form_document.id, form_document.form_slug, mode: :live, locale: :cy))
    end

    it "contains a table displaying the what happens next text in each language" do
      expect(rendered).to have_css(".govuk-summary-card__title", text: "What happens next information")
      expect(rendered).to have_css("th", text: "English content")
      expect(rendered).to include("<p class=\"govuk-body\">If you have not received a response within 5 working days, <a href=\"https://example.com\" class=\"govuk-link\" rel=\"noreferrer noopener\" target=\"_blank\">contact our user support team (opens in new tab)</a>.</p>")
      expect(rendered).to have_css("th", text: "Welsh content")
      expect(rendered).to include("<p class=\"govuk-body\">Os nad ydych wedi derbyn ymateb o fewn 5 diwrnod gwaith, <a href=\"https://example.com\" class=\"govuk-link\" rel=\"noreferrer noopener\" target=\"_blank\">cysylltwch â’n tîm cymorth defnyddwyr (agor mewn tab newydd)</a>.</p>")
    end

    context "when the form has a declaration" do
      let(:form_metadata) { create :form, :live, :with_welsh_translation, declaration_markdown:, what_happens_next_markdown:, submission_type:, submission_format: }

      it "contains a table displaying the declaration text in each language" do
        expect(rendered).to have_css(".govuk-summary-card__title", text: "Declaration")
        expect(rendered).to have_css("th", text: "English content")
        expect(rendered).to have_css("td", text: form_document.declaration_markdown)
        expect(rendered).to have_css("th", text: "Welsh content")
        expect(rendered).to have_css("td", text: welsh_form_document.declaration_markdown)
      end
    end

    context "when the form has a GOV.UK Pay payment link" do
      let(:payment_url) { "https://www.gov.uk/payments/your-payment-link" }
      let(:form_metadata) { create :form, :live, :with_welsh_translation, declaration_markdown:, what_happens_next_markdown:, submission_type:, submission_format:, payment_url: }

      it "contains a table displaying the payment link in each language" do
        expect(rendered).to have_css(".govuk-summary-card__title", text: "GOV.UK Pay payment link")
        expect(rendered).to have_css("th", text: "English content")
        expect(rendered).to have_css("td", text: form_document.payment_url)
        expect(rendered).to have_css("th", text: "Welsh content")
        expect(rendered).to have_css("td", text: welsh_form_document.payment_url)
      end
    end

    it "contains a table displaying the privacy link in each language" do
      expect(rendered).to have_css(".govuk-summary-card__title", text: "Privacy policy link")
      expect(rendered).to have_css("th", text: "English content")
      expect(rendered).to have_css("td", text: form_document.privacy_policy_url)
      expect(rendered).to have_css("th", text: "Welsh content")
      expect(rendered).to have_css("td", text: welsh_form_document.privacy_policy_url)
    end

    context "with support details" do
      let(:form_metadata) { create :form, :live, :with_welsh_translation, what_happens_next_markdown:, submission_type:, submission_format:, support_email: "support@example.gov.uk", support_phone: "phone details", support_url_text: "website", support_url: "www.example.gov.uk" }

      it "contains a table displaying the support details in each language" do
        expect(rendered).to have_css(".govuk-summary-card__title", text: "Your form’s contact details for support")
        expect(rendered).to have_css("th", text: "English content")
        expect(rendered).to have_css("th", text: "Welsh content")
        expect(rendered).to have_css("th", text: "Email")
        expect(rendered).to have_css("td", text: form_document.support_email)
        expect(rendered).to have_css("td", text: welsh_form_document.support_email)
        expect(rendered).to have_css("th", text: "Phone")
        expect(rendered).to have_css("td", text: form_document.support_phone)
        expect(rendered).to have_css("td", text: welsh_form_document.support_phone)
        expect(rendered).to have_css("th", text: "Support contact online")
        expect(rendered).to have_css("td > a[href=\"#{form_document.support_url}\"]", text: form_document.support_url_text)
        expect(rendered).to have_css("td > a[href=\"#{welsh_form_document.support_url}\"]", text: welsh_form_document.support_url_text)
      end
    end
  end
end
