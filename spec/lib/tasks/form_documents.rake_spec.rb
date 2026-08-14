require "rails_helper"

RSpec.describe "form_documents.rake", type: :task do
  describe "form_documents:show" do
    subject(:task) do
      Rake::Task["form_documents:show"]
    end

    let(:form) { create(:form) }

    it "prints the requested form document as JSON" do
      expect { task.invoke(form.id, "draft", "en") }
        .to output(/"id": #{form.draft_form_document.id}/).to_stdout
    end

    it "prints the requested English form document when no language is given" do
      expect { task.invoke(form.id, "draft") }
        .to output(/"id": #{form.draft_form_document.id}/).to_stdout
    end

    it "aborts with a usage message when arguments are missing" do
      expect {
        task.invoke(form.id)
      }.to raise_error(SystemExit)
             .and output(/usage: rake form_documents:show\[<form_id>, <tag>, <language>\]/).to_stderr
    end

    it "aborts when the tag is invalid" do
      expect {
        task.invoke(form.id, "invalid", "en")
      }.to raise_error(SystemExit)
             .and output(/tag must be one of draft, live or archived/).to_stderr
    end

    it "aborts when the language is invalid" do
      expect {
        task.invoke(form.id, "draft", "invalid")
      }.to raise_error(SystemExit)
             .and output(/language must be en or cy/).to_stderr
    end

    it "aborts when the requested form document is missing" do
      expect {
        task.invoke(form.id, "draft", "cy")
      }.to raise_error(SystemExit)
             .and output(/form #{form.id} \("#{form.name}"\) does not have a draft cy form document/).to_stderr
    end

    context "when a form has a Welsh translation" do
      let(:form) { create(:form, :with_welsh_translation) }

      it "prints the requested form document as JSON" do
        expect { task.invoke(form.id, "draft", "cy") }
          .to output(/"id": #{form.draft_welsh_form_document.id}/).to_stdout
      end
    end
  end
end
