require "rails_helper"

RSpec.describe "form_documents.rake", type: :task do
  describe "form_documents:list" do
    subject(:task) do
      Rake::Task["form_documents:list"]
    end

    before do
      freeze_time(Time.utc(2026, 8, 20, 14, 58)) do
        create(:form, :live_with_draft, id: 57)
        create(:form, :archived_with_draft, id: 90)
        create(:form, :with_welsh_translation, id: 101)
        create(:form, :live_with_draft, :with_welsh_translation, id: 1009)
      end
    end

    it "prints a table of form documents" do
      expect { task.invoke }
        .to output(
          <<~TEXT,
            form_id,tag,version,language,created_at,updated_at
            57,draft,,en,2026-08-20T14:58:00Z,2026-08-20T14:58:00Z
            57,live,1,en,2026-08-20T14:58:00Z,2026-08-20T14:58:00Z
            90,draft,,en,2026-08-20T14:58:00Z,2026-08-20T14:58:00Z
            90,archived,1,en,2026-08-20T14:58:00Z,2026-08-20T14:58:00Z
            101,draft,,en,2026-08-20T14:58:00Z,2026-08-20T14:58:00Z
            101,draft,,cy,2026-08-20T14:58:00Z,2026-08-20T14:58:00Z
            1009,draft,,en,2026-08-20T14:58:00Z,2026-08-20T14:58:00Z
            1009,draft,,cy,2026-08-20T14:58:00Z,2026-08-20T14:58:00Z
            1009,live,1,en,2026-08-20T14:58:00Z,2026-08-20T14:58:00Z
            1009,live,1,cy,2026-08-20T14:58:00Z,2026-08-20T14:58:00Z
          TEXT
        ).to_stdout
    end

    context "when given a form id argument" do
      it "prints a table of form documents for that form" do
        expect { task.invoke(1009) }
          .to output(
            <<~TEXT,
              form_id,tag,version,language,created_at,updated_at
              1009,draft,,en,2026-08-20T14:58:00Z,2026-08-20T14:58:00Z
              1009,draft,,cy,2026-08-20T14:58:00Z,2026-08-20T14:58:00Z
              1009,live,1,en,2026-08-20T14:58:00Z,2026-08-20T14:58:00Z
              1009,live,1,cy,2026-08-20T14:58:00Z,2026-08-20T14:58:00Z
            TEXT
          ).to_stdout
      end
    end
  end

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
             .and output(/usage: rake form_documents:show\[<form_id>, <ref>, <language>\]/).to_stderr
    end

    it "aborts when the tag is invalid" do
      expect {
        task.invoke(form.id, "invalid", "en")
      }.to raise_error(SystemExit)
             .and output(/ref must be version number or one of draft, live or archived/).to_stderr
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

    context "when a form has a live form document" do
      let(:form) { create(:form, :live) }

      it "prints the latest live form document as JSON" do
        expect { task.invoke(form.id, "live") }
          .to output(/"id": #{form.latest_form_document.id}/).to_stdout
      end

      it "aborts if the archived form document was requested" do
        expect {
          task.invoke(form.id, "archived", "en")
        }.to raise_error(SystemExit)
               .and output(/form #{form.id} \("#{form.name}"\) does not have a archived en form document/).to_stderr
      end

      context "when the ref argument is a version number" do
        it "prints the requested form document as JSON" do
          expect { task.invoke(form.id, "1") }
            .to output(/"id": #{form.latest_form_document.id}/).to_stdout
        end
      end
    end

    context "when a form has an archived form document" do
      let(:form) { create(:form, :archived) }

      it "prints the latest archived form document as JSON" do
        expect { task.invoke(form.id, "archived") }
          .to output(/"id": #{form.latest_form_document.id}/).to_stdout
      end

      it "aborts if the live form document was requested" do
        expect {
          task.invoke(form.id, "live", "en")
        }.to raise_error(SystemExit)
               .and output(/form #{form.id} \("#{form.name}"\) does not have a live en form document/).to_stderr
      end

      context "when the ref argument is a version number" do
        it "prints the requested form document as JSON" do
          expect { task.invoke(form.id, "1") }
            .to output(/"id": #{form.latest_form_document.id}/).to_stdout
        end
      end
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
