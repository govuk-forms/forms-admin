require "rails_helper"

describe RevertDraftFormService do
  def expect_form_state_and_content_to_be_reverted(form, expected_state)
    # reload the form to get the latest state from the database
    reloaded_form = form.reload

    expect(reloaded_form.state).to eq(expected_state.to_s)

    # We convert the form to a form document and compare the content
    # to the live form document content and check they match baring the live_at times
    # this is the closest we can get to saying there is no changes to the form
    form_document = FormDocument.find_by(form_id: form.id, tag: expected_state, language: "en")
    reloaded_form_document_content = form.reload.as_form_document
    expect(reloaded_form_document_content.except("live_at", "steps")).to eq(form_document.content.except("live_at", "steps"))

    # Compare the steps separately so we get a nice diff if the expectation fails
    reloaded_steps = reloaded_form_document_content["steps"]
    expected_steps = form_document.content["steps"]
    expect(reloaded_steps).to eq(expected_steps)
  end

  # we use `freeze_time` to freeze the timestamps of the form and its pages
  # reverting a draft will not keep the timestamps from the live version
  around { |example| freeze_time { example.run } }

  describe "when using a live form with drafts" do
    subject(:revert_draft_form_service) { described_class.new(live_form) }

    let(:live_form) { create(:form, :live_with_draft) }
    let(:live_tag) { :live }

    def revert_draft(tag)
      revert_draft_form_service.revert_draft_from_form_document(tag)
    end

    context "when the draft has no changes" do
      it "reverts a live form to its live state" do
        revert_draft(live_tag)
        expect_form_state_and_content_to_be_reverted(live_form, :live)
      end
    end

    context "when a form attribute is changed in the draft" do
      before do
        live_form.update!(name: "A new draft name")
      end

      it "reverts the attribute change" do
        revert_draft(live_tag)
        expect_form_state_and_content_to_be_reverted(live_form, :live)
      end
    end

    context "when a page attribute is changed in the draft" do
      before do
        live_form.pages.first.update!(question_text: "A new draft question text")
      end

      it "reverts the page change" do
        revert_draft(live_tag)
        expect_form_state_and_content_to_be_reverted(live_form, :live)
      end
    end

    context "when a page is added to the draft" do
      before do
        live_form.pages.create!(answer_type: "text", question_text: "A new page added to the draft", is_optional: false)
      end

      it "removes the added page" do
        revert_draft(live_tag)
        expect_form_state_and_content_to_be_reverted(live_form, :live)
      end
    end

    context "when a page is removed from the draft" do
      before do
        live_form.pages.last.destroy!
      end

      it "re-adds the removed page" do
        revert_draft(live_tag)
        expect_form_state_and_content_to_be_reverted(live_form, :live)
      end
    end

    context "with routing conditions" do
      let(:live_form) { create(:form, :ready_for_live, pages_count: 2) }

      before do
        # live version with a routing condition
        live_form.pages.first.routing_conditions.create!(
          answer_value: "Yes",
          goto_page_id: live_form.pages.last.id,
          routing_page_id: live_form.pages.first.id,
        )
        FormDocument.create!(form: live_form, tag: "live", content: live_form.as_form_document(live_at: live_form.updated_at))
        live_form.update!(state: :live_with_draft)
      end

      context "when a routing condition is added to the draft" do
        before do
          live_form.pages.first.routing_conditions.create!(
            answer_value: "No",
            goto_page_id: live_form.pages.last.id,
            routing_page_id: live_form.pages.first.id,
          )
        end

        it "removes the added routing condition" do
          revert_draft(live_tag)
          expect_form_state_and_content_to_be_reverted(live_form, :live)
        end
      end

      context "when a routing condition is removed from the draft" do
        before do
          live_form.pages.first.routing_conditions.first.destroy!
        end

        it "re-adds the removed routing condition" do
          revert_draft(live_tag)
          expect_form_state_and_content_to_be_reverted(live_form, :live)
        end
      end

      context "when a routing condition is changed in the draft" do
        before do
          live_form.pages.first.routing_conditions.first.update!(answer_value: "Maybe")
        end

        it "reverts the changed routing condition" do
          revert_draft(live_tag)
          expect_form_state_and_content_to_be_reverted(live_form, :live)
        end
      end
    end

    context "when the delivery configurations are changed in the draft" do
      let(:live_form) do
        create(:form, :live, delivery_configurations: [
          create(:delivery_configuration, :s3, formats: %w[json]),
          create(:delivery_configuration, :weekly_email),
        ])
      end

      before do
        live_form.delivery_configurations.destroy_all
        create(:delivery_configuration, :immediate_email)
        create(:delivery_configuration, :daily_email)
        live_form.delivery_configurations.reload
        live_form.save!
      end

      it "restores the delivery configurations" do
        revert_draft(live_tag)

        expect(live_form.reload.delivery_configurations.pluck(:delivery_method, :delivery_schedule, :formats)).to contain_exactly(
          ["s3", "immediate", %w[json]],
          ["email", "weekly", %w[csv]],
        )
      end
    end

    context "when form has Welsh content" do
      let(:live_form) do
        form = create(:form, :live, :with_pages, pages_count: 2, available_languages: %w[en cy], support_phone: "01234 567890", support_url: "https://example.gov.uk/support", support_url_text: "Our English support site", declaration_markdown: "English declaration", payment_url: "https://www.pay.gov.uk")
        # Set Welsh translations for the form
        form.name_cy = "Ffurflen Gymraeg"
        form.privacy_policy_url_cy = "https://example.com/preifatrwydd"
        form.support_email_cy = "cymorth@example.com"
        form.support_phone_cy = "0800 111 222"
        form.declaration_markdown = "Rwy'n datgan bod hyn yn wir"
        form.save!
        form.pages.first.hint_text = "English first page hint text"
        form.pages.last.hint_text = "English last page hint text"
        # Set Welsh translations for pages
        form.pages.first.update!(question_text_cy: "Cwestiwn Cymraeg 1", hint_text_cy: "Awgrym Cymraeg 1")
        form.pages.last.update!(question_text_cy: "Cwestiwn Cymraeg 2", hint_text_cy: "Awgrym Cymraeg 2")
        # Synchronize live FormDocuments for both languages
        FormDocumentSyncService.new(form).synchronize_live_form
        # Make the form live_with_draft
        form.create_draft_from_live_form!
        form.reload
        form
      end

      context "when Welsh translations are changed in the draft" do
        before do
          # Change Welsh translations in the draft
          live_form.name_cy = "Ffurflen Cymraeg Newydd"
          live_form.support_email_cy = "cymorth_newydd@example.com"
          live_form.pages.first.update!(question_text_cy: "Cwestiwn Newydd 1")
          live_form.save!
        end

        it "restores the original Welsh translations from the live version" do
          revert_draft(live_tag)

          # Reload to get the restored state
          live_form.reload

          # Check that form-level Welsh translations are restored
          expect(live_form.name_cy).to eq("Ffurflen Gymraeg")
          expect(live_form.privacy_policy_url_cy).to eq("https://example.com/preifatrwydd")
          expect(live_form.support_email_cy).to eq("cymorth@example.com")
          expect(live_form.support_phone_cy).to eq("0800 111 222")
          expect(live_form.declaration_markdown_cy).to eq("Rwy'n datgan bod hyn yn wir")

          # Check that page-level Welsh translations are restored
          expect(live_form.pages.first.question_text_cy).to eq("Cwestiwn Cymraeg 1")
          expect(live_form.pages.first.hint_text_cy).to eq("Awgrym Cymraeg 1")
          expect(live_form.pages.last.question_text_cy).to eq("Cwestiwn Cymraeg 2")
          expect(live_form.pages.last.hint_text_cy).to eq("Awgrym Cymraeg 2")

          # Verify Welsh content is accessible in Welsh locale
          Mobility.with_locale(:cy) do
            expect(live_form.name).to eq("Ffurflen Gymraeg")
            expect(live_form.support_email).to eq("cymorth@example.com")
            expect(live_form.pages.first.question_text).to eq("Cwestiwn Cymraeg 1")
          end
        end
      end

      context "when Welsh FormDocument exists in live but is modified in draft" do
        before do
          # Modify the form's Welsh content in draft
          live_form.update!(name_cy: "Ffurflen Wedi'i Diwygio")
        end

        it "restores the Welsh FormDocument to match the live version" do
          # Get the original live Welsh FormDocument content
          original_welsh_doc = FormDocument.find_by(form_id: live_form.id, tag: "live", language: "cy")
          expect(original_welsh_doc).to be_present
          original_welsh_name = original_welsh_doc.content["name"]
          expect(original_welsh_name).to eq("Ffurflen Gymraeg")

          revert_draft(live_tag)

          # After reverting, the Welsh FormDocument should be restored
          live_form.reload
          restored_welsh_doc = FormDocument.find_by(form_id: live_form.id, tag: "draft", language: "cy")
          expect(restored_welsh_doc).to be_present
          expect(restored_welsh_doc.content["name"]).to eq("Ffurflen Gymraeg")
          expect(live_form.name_cy).to eq("Ffurflen Gymraeg")
        end
      end

      context "when conditions have Welsh translations in live version" do
        let(:live_form) do
          form = create(:form, :live, pages_count: 2, available_languages: %w[en cy])
          # Set up a condition with Welsh translations
          form.pages.first.update!(answer_type: "selection", answer_settings: { "only_one_option" => "true", "selection_options" => [{ "name" => "Yes" }, { "name" => "No" }] })
          condition = form.pages.first.routing_conditions.create!(
            goto_page_id: form.pages.last.id,
            exit_page_heading: "Exit page heading",
            exit_page_markdown: "Exit page markdown",
          )
          # Set Welsh translations for the condition
          condition.exit_page_heading_cy = "Welsh Exit page heading"
          condition.save!
          # Synchronize live FormDocuments for both languages
          FormDocumentSyncService.new(form).synchronize_live_form
          # Make the form live_with_draft
          form.create_draft_from_live_form!
          form.reload
          form
        end

        context "when Welsh translations are changed in the draft" do
          before do
            # Change Welsh translation in the draft
            condition = live_form.pages.first.routing_conditions.first
            condition.exit_page_heading_cy = "New Welsh Exit page heading"
            condition.save!
          end

          it "restores the original Welsh translations for conditions" do
            revert_draft(live_tag)

            # Reload to get the restored state
            live_form.reload
            condition = live_form.pages.first.routing_conditions.first

            # Check that condition-level Welsh translations are restored
            expect(condition.exit_page_heading_cy).to eq("Welsh Exit page heading")

            # Verify Welsh content is accessible in Welsh locale
            Mobility.with_locale(:cy) do
              expect(condition.exit_page_heading).to eq("Welsh Exit page heading")
            end
          end
        end
      end

      context "when conditions have exit page Welsh translations in live version" do
        let(:live_form) do
          form = create(:form, :live, pages_count: 2, available_languages: %w[en cy])
          form.pages.first.update!(answer_type: "selection", answer_settings: { "only_one_option" => "true", "selection_options" => [{ "name" => "Yes" }, { "name" => "No" }] })
          condition = form.pages.first.routing_conditions.create!(
            answer_value: "No",
            routing_page_id: form.pages.first.id,
            exit_page_heading: "You cannot continue",
            exit_page_markdown: "Please contact us",
          )
          # Set Welsh translations for exit page content
          condition.exit_page_heading_cy = "Ni allwch barhau"
          condition.exit_page_markdown_cy = "Cysylltwch â ni"
          condition.save!
          # Synchronize live FormDocuments for both languages
          FormDocumentSyncService.new(form).synchronize_live_form
          # Make the form live_with_draft
          form.create_draft_from_live_form!
          form.reload
          form
        end

        context "when exit page Welsh translations are changed in the draft" do
          before do
            condition = live_form.pages.first.routing_conditions.first
            condition.exit_page_heading_cy = "Ni allwch fynd ymlaen"
            condition.exit_page_markdown_cy = "Ffoniwch ni"
            condition.save!
          end

          it "restores the original exit page Welsh translations for conditions" do
            revert_draft(live_tag)

            live_form.reload
            condition = live_form.pages.first.routing_conditions.first

            expect(condition.exit_page_heading_cy).to eq("Ni allwch barhau")
            expect(condition.exit_page_markdown_cy).to eq("Cysylltwch â ni")

            Mobility.with_locale(:cy) do
              expect(condition.exit_page_heading).to eq("Ni allwch barhau")
              expect(condition.exit_page_markdown).to eq("Cysylltwch â ni")
            end
          end
        end
      end
    end

    context "when form has no Welsh content in live but Welsh is added in draft" do
      let(:live_form) do
        form = create(:form, :live, :with_pages, pages_count: 2)
        # Create live FormDocument without Welsh version
        FormDocumentSyncService.new(form).synchronize_live_form
        form.create_draft_from_live_form!
        form.reload
        form
      end

      context "when Welsh translations are added to the draft" do
        before do
          live_form.update!(name_cy: "Ffurflen Gymraeg Newydd", available_languages: %w[en cy])
          live_form.pages.first.update!(question_text_cy: "Cwestiwn Cymraeg")
        end

        it "removes the Welsh translations when reverting to live" do
          revert_draft(live_tag)

          live_form.reload

          # Check that Welsh translations are cleared
          expect(live_form.name_cy).to be_nil
          expect(live_form.pages.first.question_text_cy).to be_nil
        end
      end

      context "when Welsh translations are added to conditions in the draft" do
        let(:live_form) do
          form = create(:form, :live, pages_count: 2)
          form.pages.first.update!(answer_type: "selection", answer_settings: { "only_one_option" => "true", "selection_options" => [{ "name" => "Yes" }, { "name" => "No" }] })
          form.pages.first.routing_conditions.create!(
            goto_page_id: form.pages.last.id,
            exit_page_heading: "Exit page heading",
            exit_page_markdown: "Exit page markdown",
          )
          # Synchronize live FormDocument (no Welsh version)
          FormDocumentSyncService.new(form).synchronize_live_form
          form.create_draft_from_live_form!
          form.reload
          form
        end

        before do
          # Add Welsh translations to condition in draft
          condition = live_form.pages.first.routing_conditions.first
          condition.exit_page_heading_cy = "Welsh Exit page heading"
          condition.save!
        end

        it "removes the Welsh translations from conditions when reverting to live" do
          revert_draft(live_tag)

          live_form.reload
          condition = live_form.pages.first.routing_conditions.first

          expect(condition.exit_page_heading_cy).to be_nil
        end
      end

      context "when Welsh exit page translations are added to conditions in the draft" do
        let(:live_form) do
          form = create(:form, :live, pages_count: 2)
          form.pages.first.update!(answer_type: "selection", answer_settings: { "only_one_option" => "true", "selection_options" => [{ "name" => "Yes" }, { "name" => "No" }] })
          form.pages.first.routing_conditions.create!(
            answer_value: "No",
            routing_page_id: form.pages.first.id,
            exit_page_heading: "You cannot continue",
            exit_page_markdown: "Please contact us",
          )
          # Synchronize live FormDocument (no Welsh version)
          FormDocumentSyncService.new(form).synchronize_live_form
          form.create_draft_from_live_form!
          form.reload
          form
        end

        before do
          # Add Welsh exit page translations to condition in draft
          condition = live_form.pages.first.routing_conditions.first
          condition.exit_page_heading_cy = "Ni allwch barhau"
          condition.exit_page_markdown_cy = "Cysylltwch â ni"
          condition.save!
        end

        it "removes the Welsh exit page translations from conditions when reverting to live" do
          revert_draft(live_tag)

          live_form.reload
          condition = live_form.pages.first.routing_conditions.first

          expect(condition.exit_page_heading_cy).to be_nil
          expect(condition.exit_page_markdown_cy).to be_nil
        end
      end
    end
  end

  describe "when using an archived form with drafts" do
    subject(:revert_draft_form_service) { described_class.new(archived_form) }

    let(:archived_form) { create(:form, :archived_with_draft) }
    let(:archived_tag) { :archived }

    def revert_draft(tag)
      revert_draft_form_service.revert_draft_from_form_document(tag)
    end

    context "when the draft has no changes" do
      it "reverts an archived form to its archived state" do
        revert_draft(archived_tag)
        expect_form_state_and_content_to_be_reverted(archived_form, :archived)
      end
    end

    context "when a form attribute is changed in the draft" do
      before do
        archived_form.update!(name: "A new draft name")
      end

      it "reverts the attribute change" do
        revert_draft(archived_tag)
        expect_form_state_and_content_to_be_reverted(archived_form, :archived)
      end
    end

    context "when a page attribute is changed in the draft" do
      before do
        archived_form.pages.first.update!(question_text: "A new draft question text")
      end

      it "reverts the page change" do
        revert_draft(archived_tag)
        expect_form_state_and_content_to_be_reverted(archived_form, :archived)
      end
    end

    context "when a page is added to the draft" do
      before do
        archived_form.pages.create!(answer_type: "text", question_text: "A new page added to the draft", is_optional: false)
      end

      it "removes the added page" do
        revert_draft(archived_tag)
        expect_form_state_and_content_to_be_reverted(archived_form, :archived)
      end
    end

    context "when a page is removed from the draft" do
      before do
        archived_form.pages.last.destroy!
      end

      it "re-adds the removed page" do
        revert_draft(archived_tag)
        expect_form_state_and_content_to_be_reverted(archived_form, :archived)
      end
    end

    context "with routing conditions" do
      let(:archived_form) { create(:form, :ready_for_live, pages_count: 2) }

      before do
        # archived version with a routing condition
        archived_form.pages.first.routing_conditions.create!(
          answer_value: "Yes",
          goto_page_id: archived_form.pages.last.id,
          routing_page_id: archived_form.pages.first.id,
        )
        FormDocument.create!(form: archived_form, tag: "archived", content: archived_form.as_form_document(live_at: archived_form.updated_at))
        archived_form.update!(state: :archived_with_draft)
      end

      context "when a routing condition is added to the draft" do
        before do
          archived_form.pages.first.routing_conditions.create!(
            answer_value: "No",
            goto_page_id: archived_form.pages.last.id,
            routing_page_id: archived_form.pages.first.id,
          )
        end

        it "removes the added routing condition" do
          revert_draft(archived_tag)
          expect_form_state_and_content_to_be_reverted(archived_form, :archived)
        end
      end

      context "when a routing condition is removed from the draft" do
        before do
          archived_form.pages.first.routing_conditions.first.destroy!
        end

        it "re-adds the removed routing condition" do
          revert_draft(archived_tag)
          expect_form_state_and_content_to_be_reverted(archived_form, :archived)
        end
      end

      context "when a routing condition is changed in the draft" do
        before do
          archived_form.pages.first.routing_conditions.first.update!(answer_value: "Maybe")
        end

        it "reverts the changed routing condition" do
          revert_draft(archived_tag)
          expect_form_state_and_content_to_be_reverted(archived_form, :archived)
        end
      end
    end
  end
end
