require "rails_helper"

RSpec.describe "forms.rake", type: :task do
  describe "forms:move" do
    subject(:task) do
      Rake::Task["forms:move"]
    end

    let(:group) { create :group }
    let(:forms) { create_list(:form, 3) }
    let(:form_ids) { forms.map(&:id) }

    context "with valid arguments" do
      context "with a single form not in a group" do
        let(:form_id) { form_ids.first }
        let(:valid_args) { [form_id, group.external_id] }

        it "adds the form to the group" do
          expect {
            task.invoke(*valid_args)
          }.to change(GroupForm, :count).by(1)

          expect(GroupForm.last).to eq(GroupForm.new(form_id:, group:))
        end
      end

      context "with a single form already in a group" do
        let(:form_id) { form_ids.first }
        let(:old_group) { create :group }
        let(:valid_args) { [form_id, group.external_id] }

        before do
          GroupForm.create! form_id:, group: old_group
        end

        it "adds the form to the group" do
          expect {
            task.invoke(*valid_args)
          }.not_to change(GroupForm, :count)

          expect(GroupForm.find_by(form_id:))
            .to eq(GroupForm.new(form_id:, group:))
        end
      end

      context "with a single form already in the target group" do
        let(:form_id) { form_ids.first }
        let(:valid_args) { [form_id, group.external_id] }

        before do
          GroupForm.create! form_id:, group:
        end

        it "keeps the form in the group" do
          expect {
            task.invoke(*valid_args)
          }.not_to change(GroupForm, :count)

          expect(GroupForm.find_by(form_id:))
            .to eq(GroupForm.new(form_id:, group:))
        end
      end

      context "with a multiple forms" do
        let(:valid_args) { [*form_ids, group.external_id] }

        it "adds each form to the group" do
          task.invoke(*valid_args)

          form_ids.each do |form_id|
            expect(GroupForm.find_by(form_id:))
              .to eq(GroupForm.new(form_id:, group:))
          end
        end
      end
    end

    context "with invalid arguments" do
      shared_examples_for "usage error" do
        it "aborts with a usage message" do
          expect {
            task.invoke(*invalid_args)
          }.to raise_error(SystemExit)
                 .and output(/usage: rake forms:move/).to_stderr
        end
      end

      context "with no arguments" do
        it_behaves_like "usage error" do
          let(:invalid_args) { [] }
        end
      end

      context "with only one argument" do
        it_behaves_like "usage error" do
          let(:invalid_args) { [form_ids.first] }
        end
      end

      context "with invalid group_id" do
        let(:invalid_args) { [*form_ids, "not_a_group_id"] }

        it "raises an error" do
          expect {
            task.invoke(*invalid_args)
          }.to raise_error(ActiveRecord::RecordNotFound, /Couldn't find Group/)
        end
      end

      context "with invalid form_id" do
        let(:invalid_args) { ["99", group.external_id] }

        it "raises an error" do
          expect {
            task.invoke(*invalid_args)
          }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end
  end

  describe "forms:set_state" do
    subject(:task) do
      Rake::Task["forms:set_state"]
    end

    let(:form) { create :form, :ready_for_live }
    let!(:other_form) { create :form }

    context "with valid arguments" do
      it "sets a draft form's state to archived by transitioning through live" do
        expect {
          task.invoke(form.id, "archived")
        }.to change { form.reload.state }.from("draft").to("archived")
      end

      it "runs the event callbacks for the intermediate transitions" do
        task.invoke(form.id, "archived")

        form.reload
        expect(form.first_made_live_at).not_to be_nil
        expect(form.latest_form_document).not_to be_nil
      end

      it "sets a draft form's state to archived_with_draft by transitioning through two intermediate states" do
        expect {
          task.invoke(form.id, "archived_with_draft")
        }.to change { form.reload.state }.from("draft").to("archived_with_draft")
      end

      it "sets an archived form's state to live" do
        archived_form = create :form, :archived

        expect {
          task.invoke(archived_form.id, "live")
        }.to change { archived_form.reload.state }.from("archived").to("live")
      end

      it "does not change other forms" do
        expect {
          task.invoke(form.id, "archived")
        }.not_to(change { other_form.reload.state })
      end
    end

    context "when the form is not ready to be made live" do
      let(:form) { create :form }

      it "raises an invalid transition error and does not change the form's state" do
        expect {
          task.invoke(form.id, "archived")
        }.to raise_error(AASM::InvalidTransition)

        expect(form.reload.state).to eq("draft")
      end
    end

    context "when no sequence of events reaches the target state" do
      it "aborts with a message" do
        live_form = create :form, :live

        expect {
          task.invoke(live_form.id, "draft")
        }.to raise_error(SystemExit)
               .and output(/cannot transition form from 'live' to 'draft'/).to_stderr
      end
    end

    context "when the form is already in the target state" do
      it "does not abort and leaves the form's state unchanged" do
        expect {
          task.invoke(form.id, "draft")
        }.not_to raise_error

        expect(form.reload.state).to eq("draft")
      end

      it "logs that the form is already in the target state" do
        allow(Rails.logger).to receive(:info)

        task.invoke(form.id, "draft")

        expect(Rails.logger).to have_received(:info)
                                  .with(/forms:set_state: form #{form.id} \(".*"\) is already in state 'draft'/)
      end
    end

    context "with invalid arguments" do
      shared_examples_for "usage error" do
        it "aborts with a usage message" do
          expect {
            task.invoke(*invalid_args)
          }.to raise_error(SystemExit)
                 .and output(/usage: rake forms:set_state/).to_stderr
        end
      end

      context "with no arguments" do
        it_behaves_like "usage error" do
          let(:invalid_args) { [] }
        end
      end

      context "with only one argument" do
        it_behaves_like "usage error" do
          let(:invalid_args) { [form.id] }
        end
      end

      context "with a state that is not a form state" do
        it "aborts with a message listing the valid states" do
          expect {
            task.invoke(form.id, "not_a_state")
          }.to raise_error(SystemExit)
                 .and output(/state must be one of draft, deleted, live, live_with_draft, archived, archived_with_draft/).to_stderr
        end
      end

      context "with invalid form_id" do
        it "raises an error" do
          expect {
            task.invoke("99", "archived")
          }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end
  end

  describe "forms:submission_email:update" do
    subject(:task) do
      Rake::Task["forms:submission_email:update"]
    end

    let(:form) do
      create :form
    end

    context "with valid arguments" do
      let(:submission_email) { "test@example.gov.uk" }
      let(:valid_args) { [form.id, submission_email] }

      shared_examples "submission email update" do
        it "changes the form submission email" do
          expect {
            task.invoke(*valid_args)
          }.to change { form.reload.submission_email }.to(submission_email)
        end

        it "updates the email confirmation status" do
          task.invoke(*valid_args)
          expect(form.reload.email_confirmation_status).to eq(:email_set_without_confirmation)
        end
      end

      include_examples "submission email update"

      context "when the form has a submission email record" do
        include_examples "submission email update"

        it "is deleted" do
          form_submission_email = FormSubmissionEmail.create!(form_id: form.id)

          expect {
            task.invoke(*valid_args)
          }.to change(FormSubmissionEmail, :count).by(-1)

          expect {
            form_submission_email.reload
          }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context "when the submission email is not a government email address" do
        let(:submission_email) { "test@example.aws.com" }

        include_examples "submission email update"

        it "does not raise a validation error" do
          expect {
            task.invoke(*valid_args)
          }.not_to raise_error
        end
      end
    end

    context "with invalid arguments" do
      shared_examples_for "usage error" do
        it "aborts with a usage message" do
          expect {
            task.invoke(*invalid_args)
          }.to raise_error(SystemExit)
                 .and output(/usage: rake forms:submission_email:update/).to_stderr
        end
      end

      context "with no arguments" do
        it_behaves_like "usage error" do
          let(:invalid_args) { [] }
        end
      end

      context "with only one argument" do
        it_behaves_like "usage error" do
          let(:invalid_args) { [form.id] }
        end
      end

      context "with invalid form_id" do
        let(:invalid_args) { ["99", "test@example.com"] }

        it "raises an error" do
          expect {
            task.invoke(*invalid_args)
          }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context "with invalid email address" do
        let(:invalid_args) { %w[99 not_an_email_address] }

        it "raises an error" do
          expect {
            task.invoke(*invalid_args)
          }.to raise_error(/not an email address/)
        end
      end
    end
  end

  describe "forms:delivery_configurations:enable_email" do
    subject(:task) do
      Rake::Task["forms:delivery_configurations:enable_email"]
    end

    let(:form) { create(:form) }

    context "with valid arguments" do
      it "adds immediate email delivery to the form" do
        expect {
          task.invoke(form.id)
        }.to change { form.reload.delivery_configurations.where(delivery_method: "email", delivery_schedule: "immediate").count }
               .by(1)
      end

      it "updates the draft form document delivery configurations" do
        task.invoke(form.id)

        expect(form.reload.draft_form_document.content["delivery_configurations"])
          .to include(a_hash_including("delivery_method" => "email", "delivery_schedule" => "immediate"))
      end

      context "when the form is live" do
        let(:form) { create(:form, :live, :with_welsh_translation) }

        it "updates the live form documents delivery configurations" do
          task.invoke(form.id)

          expect(form.reload.latest_form_document.content["delivery_configurations"])
            .to include(a_hash_including("delivery_method" => "email", "delivery_schedule" => "immediate"))
          expect(form.reload.latest_welsh_form_document.content["delivery_configurations"])
            .to include(a_hash_including("delivery_method" => "email", "delivery_schedule" => "immediate"))
        end
      end

      context "when email is already enabled" do
        let(:form) { create(:form, :live, :with_welsh_translation) }

        it "does not change the delivery configurations or form documents" do
          task.invoke(form.id)

          delivery_configuration_count = form.reload.delivery_configurations.where(delivery_method: "email", delivery_schedule: "immediate").count
          draft_content = form.reload.draft_form_document.content.deep_dup
          live_content = form.reload.latest_form_document.content.deep_dup
          live_welsh_content = form.reload.latest_welsh_form_document.content.deep_dup

          task.invoke(form.id)

          expect(form.reload.delivery_configurations.where(delivery_method: "email", delivery_schedule: "immediate").count)
            .to eq(delivery_configuration_count)

          expect(form.reload.draft_form_document.content).to eq(draft_content)
          expect(form.reload.latest_form_document.content).to eq(live_content)
          expect(form.reload.latest_welsh_form_document&.content).to eq(live_welsh_content)
        end
      end
    end

    context "with invalid arguments" do
      it "aborts with a usage message when the form id is missing" do
        expect {
          task.invoke
        }.to raise_error(SystemExit)
               .and output(/usage: rake forms:delivery_configurations:enable_email\[<form_id>\]/).to_stderr
      end
    end
  end

  describe "forms:delivery_configurations:disable_email" do
    subject(:task) do
      Rake::Task["forms:delivery_configurations:disable_email"]
    end

    let(:form) do
      create(:form, :live, :with_welsh_translation, delivery_configurations: [
        create(:delivery_configuration, :immediate_email),
        create(:delivery_configuration, :s3),
      ])
    end

    context "with valid arguments" do
      it "removes immediate email delivery from the form" do
        expect {
          task.invoke(form.id)
        }.to change { form.reload.delivery_configurations.where(delivery_method: "email", delivery_schedule: "immediate").count }
               .by(-1)
      end

      it "updates the draft form document delivery configurations" do
        task.invoke(form.id)

        expect(form.reload.draft_form_document.content["delivery_configurations"])
          .not_to include(a_hash_including("delivery_method" => "email", "delivery_schedule" => "immediate"))
      end

      context "when the form is live" do
        it "updates the live form documents delivery configurations" do
          task.invoke(form.id)

          expect(form.reload.latest_form_document.content["delivery_configurations"])
            .not_to include(a_hash_including("delivery_method" => "email", "delivery_schedule" => "immediate"))
          expect(form.reload.latest_welsh_form_document.content["delivery_configurations"])
            .not_to include(a_hash_including("delivery_method" => "email", "delivery_schedule" => "immediate"))
        end
      end
    end

    context "with invalid arguments" do
      it "aborts with a usage message when the form id is missing" do
        expect {
          task.invoke
        }.to raise_error(SystemExit)
               .and output(/usage: rake forms:delivery_configurations:disable_email\[<form_id>\]/).to_stderr
      end

      context "when email is already disabled" do
        let(:form) do
          create(:form, :live, :with_welsh_translation, delivery_configurations: [create(:delivery_configuration, :s3)])
        end

        it "aborts with an error" do
          expect {
            task.invoke(form.id)
          }.to raise_error(SystemExit)
                 .and output(/Email delivery is not enabled/).to_stderr
        end
      end

      context "when the form would have no delivery methods if email delivery is disabled" do
        let(:form) do
          create(:form, :live, :with_welsh_translation, :with_email_delivery)
        end

        it "aborts with an error" do
          expect {
            task.invoke(form.id)
          }.to raise_error(SystemExit)
                 .and output(/Form will have no delivery methods, enable S3 delivery first/).to_stderr
        end
      end
    end
  end

  describe "forms:delivery_configurations:disable_s3" do
    subject(:task) do
      Rake::Task["forms:delivery_configurations:disable_s3"]
    end

    let(:form) do
      create(:form, :live, :with_welsh_translation, :with_s3_configuration, delivery_configurations: [
        create(:delivery_configuration, :s3),
        create(:delivery_configuration, :immediate_email),
      ])
    end

    context "with valid arguments" do
      it "removes immediate S3 delivery from the form" do
        expect {
          task.invoke(form.id)
        }.to change { form.reload.delivery_configurations.where(delivery_method: "s3", delivery_schedule: "immediate").count }
               .by(-1)
      end

      it "clears the form S3 configuration" do
        expect {
          task.invoke(form.id)
        }.to change { form.reload.s3_bucket_name }.to(nil)
                                                  .and change { form.reload.s3_bucket_aws_account_id }.to(nil)
                                                                                                      .and change { form.reload.s3_bucket_region }.to(nil)
      end

      it "updates the draft form document" do
        task.invoke(form.id)

        expect(form.reload.draft_form_document.content["s3_bucket_name"]).to be_nil
        expect(form.reload.draft_form_document.content["s3_bucket_aws_account_id"]).to be_nil
        expect(form.reload.draft_form_document.content["s3_bucket_region"]).to be_nil
        expect(form.reload.draft_form_document.content["delivery_configurations"])
          .not_to include(a_hash_including("delivery_method" => "s3", "delivery_schedule" => "immediate"))
      end

      context "when the form is live" do
        it "updates the live form documents" do
          task.invoke(form.id)

          expect(form.reload.latest_form_document.content["s3_bucket_name"]).to be_nil
          expect(form.reload.latest_form_document.content["s3_bucket_aws_account_id"]).to be_nil
          expect(form.reload.latest_form_document.content["s3_bucket_region"]).to be_nil
          expect(form.reload.latest_form_document.content["delivery_configurations"])
            .not_to include(a_hash_including("delivery_method" => "s3", "delivery_schedule" => "immediate"))

          expect(form.reload.latest_welsh_form_document.content["s3_bucket_name"]).to be_nil
          expect(form.reload.latest_welsh_form_document.content["s3_bucket_aws_account_id"]).to be_nil
          expect(form.reload.latest_welsh_form_document.content["s3_bucket_region"]).to be_nil
          expect(form.reload.latest_welsh_form_document.content["delivery_configurations"])
            .not_to include(a_hash_including("delivery_method" => "s3", "delivery_schedule" => "immediate"))
        end
      end
    end

    context "with invalid arguments" do
      it "aborts with a usage message when the form id is missing" do
        expect {
          task.invoke
        }.to raise_error(SystemExit)
               .and output(/usage: rake forms:delivery_configurations:disable_s3\[<form_id>\]/).to_stderr
      end

      context "when S3 delivery is not enabled" do
        let(:form) do
          create(:form, :live, :with_welsh_translation, :with_email_delivery)
        end

        it "aborts with an error" do
          expect {
            task.invoke(form.id)
          }.to raise_error(SystemExit)
                 .and output(/S3 delivery is not enabled/).to_stderr
        end
      end

      context "when the form would have no delivery methods if S3 delivery is disabled" do
        let(:form) do
          create(:form, :live, :with_welsh_translation, delivery_configurations: [create(:delivery_configuration, :s3)])
        end

        it "aborts with an error" do
          expect {
            task.invoke(form.id)
          }.to raise_error(SystemExit)
                 .and output(/Form will have no delivery methods, enable email delivery first/).to_stderr
        end
      end
    end
  end

  describe "forms:delivery_configurations:enable_s3" do
    subject(:task) do
      Rake::Task["forms:delivery_configurations:enable_s3"]
    end

    let(:form) { create(:form, :live, :with_welsh_translation, :with_email_delivery) }
    let(:s3_bucket_name) { "test-bucket" }
    let(:s3_bucket_aws_account_id) { "123456789012" }
    let(:s3_bucket_region) { "eu-west-1" }
    let(:format) { "csv" }
    let(:disable_email) { "false" }
    let(:valid_args) { [form.id, s3_bucket_name, s3_bucket_aws_account_id, s3_bucket_region, format, disable_email] }

    context "with valid arguments" do
      it "updates the form S3 configuration" do
        expect {
          task.invoke(*valid_args)
        }.to change { form.reload.s3_bucket_name }.to(s3_bucket_name)
                                                  .and change { form.reload.s3_bucket_aws_account_id }.to(s3_bucket_aws_account_id)
                                                                                                      .and change { form.reload.s3_bucket_region }.to(s3_bucket_region)
      end

      it "adds S3 delivery and keeps email enabled" do
        expect {
          task.invoke(*valid_args)
        }.to change { form.reload.delivery_configurations.where(delivery_method: "s3", delivery_schedule: "immediate").count }
               .by(1)

        expect(form.reload.delivery_configurations.where(delivery_method: "email", delivery_schedule: "immediate").count)
          .to eq(1)
        expect(form.reload.delivery_configurations.find_by(delivery_method: "s3", delivery_schedule: "immediate").formats)
          .to eq([format])
      end

      it "updates the draft and live form documents" do
        task.invoke(*valid_args)

        expect(form.reload.draft_form_document.content["s3_bucket_name"]).to eq(s3_bucket_name)
        expect(form.reload.draft_form_document.content["s3_bucket_aws_account_id"]).to eq(s3_bucket_aws_account_id)
        expect(form.reload.draft_form_document.content["s3_bucket_region"]).to eq(s3_bucket_region)

        expect(form.reload.latest_form_document.content["s3_bucket_name"]).to eq(s3_bucket_name)
        expect(form.reload.latest_form_document.content["s3_bucket_aws_account_id"]).to eq(s3_bucket_aws_account_id)
        expect(form.reload.latest_form_document.content["s3_bucket_region"]).to eq(s3_bucket_region)

        expect(form.reload.latest_welsh_form_document.content["s3_bucket_name"]).to eq(s3_bucket_name)
        expect(form.reload.latest_welsh_form_document.content["s3_bucket_aws_account_id"]).to eq(s3_bucket_aws_account_id)
        expect(form.reload.latest_welsh_form_document.content["s3_bucket_region"]).to eq(s3_bucket_region)

        expect(form.reload.draft_form_document.content["delivery_configurations"])
          .to include(a_hash_including("delivery_method" => "s3", "delivery_schedule" => "immediate", "formats" => [format]))
        expect(form.reload.latest_form_document.content["delivery_configurations"])
          .to include(a_hash_including("delivery_method" => "s3", "delivery_schedule" => "immediate", "formats" => [format]))
        expect(form.reload.latest_welsh_form_document.content["delivery_configurations"])
          .to include(a_hash_including("delivery_method" => "s3", "delivery_schedule" => "immediate", "formats" => [format]))
      end

      context "when there is already an S3 delivery configuration" do
        let(:form) do
          create(:form, :live, :with_welsh_translation, delivery_configurations: [
            create(:delivery_configuration, :s3, formats: %w[json]),
          ])
        end

        it "updates the format for the existing configuration" do
          task.invoke(*valid_args)

          expect(form.reload.delivery_configurations.find_by(delivery_method: "s3", delivery_schedule: "immediate").formats)
            .to eq(%w[csv])

          expect(form.reload.draft_form_document.content["delivery_configurations"])
            .to include(a_hash_including("delivery_method" => "s3", "delivery_schedule" => "immediate", "formats" => %w[csv]))
          expect(form.reload.latest_form_document.content["delivery_configurations"])
            .to include(a_hash_including("delivery_method" => "s3", "delivery_schedule" => "immediate", "formats" => %w[csv]))
          expect(form.reload.latest_welsh_form_document.content["delivery_configurations"])
            .to include(a_hash_including("delivery_method" => "s3", "delivery_schedule" => "immediate", "formats" => %w[csv]))
        end
      end

      context "when disable_email is true" do
        let(:disable_email) { "true" }

        it "removes email delivery" do
          expect {
            task.invoke(*valid_args)
          }.to change { form.reload.delivery_configurations.where(delivery_method: "email", delivery_schedule: "immediate").count }
                 .by(-1)

          expect(form.reload.draft_form_document.content["delivery_configurations"])
            .not_to include(a_hash_including("delivery_method" => "email", "delivery_schedule" => "immediate"))
          expect(form.reload.latest_form_document.content["delivery_configurations"])
            .not_to include(a_hash_including("delivery_method" => "email", "delivery_schedule" => "immediate"))
          expect(form.reload.latest_welsh_form_document.content["delivery_configurations"])
            .not_to include(a_hash_including("delivery_method" => "email", "delivery_schedule" => "immediate"))

          expect(form.reload.latest_form_document.content["s3_bucket_name"]).to eq(s3_bucket_name)
          expect(form.reload.latest_form_document.content["s3_bucket_aws_account_id"]).to eq(s3_bucket_aws_account_id)
          expect(form.reload.latest_form_document.content["s3_bucket_region"]).to eq(s3_bucket_region)

          expect(form.reload.latest_welsh_form_document.content["s3_bucket_name"]).to eq(s3_bucket_name)
          expect(form.reload.latest_welsh_form_document.content["s3_bucket_aws_account_id"]).to eq(s3_bucket_aws_account_id)
          expect(form.reload.latest_welsh_form_document.content["s3_bucket_region"]).to eq(s3_bucket_region)
        end
      end
    end

    context "with invalid arguments" do
      it "aborts with a usage message when the form id is missing" do
        expect {
          task.invoke
        }.to raise_error(SystemExit)
               .and output(/usage: rake forms:delivery_configurations:enable_s3\[<form_id>, <s3_bucket_name>, <s3_bucket_aws_account_id>, <s3_bucket_region>, <format>, <disable_email>\]/).to_stderr
      end
    end
  end

  describe "forms:list_contact_emails" do
    subject(:task) do
      Rake::Task["forms:list_contact_emails"]
    end

    let(:organisation) { create :organisation, :with_signed_mou, name: "Test Org" }
    let(:group) { create :group, name: "Test Group", organisation: }
    let(:creator) { create :user, organisation: }
    let(:group_admin) { create :user, organisation: }
    let(:org_admin) { create :organisation_admin_user, organisation: }
    let(:form) { create :form, name: "Test Form", creator_id: creator.id }

    before do
      GroupForm.create!(form_id: form.id, group:)
      create :membership, group:, user: group_admin, role: :group_admin
      org_admin
    end

    it "prints the contact emails for the form" do
      expect {
        task.invoke(form.id)
      }.to output(
        include("Form ID: #{form.id}, Form Name: Test Form, Organisation: Test Org, Group: Test Group")
          .and(include("Form creator: #{creator.email}"))
          .and(include("Group admins: #{group_admin.email}"))
          .and(include("Organisation admins: #{org_admin.email}")),
      ).to_stdout
    end

    context "when the form has no creator" do
      let(:form) { create :form, creator_id: nil }

      it "prints the creator as Unknown" do
        expect { task.invoke(form.id) }.to output(/Form creator: Unknown/).to_stdout
      end
    end

    context "with multiple forms" do
      let(:other_form) { create :form, name: "Other Form" }

      before do
        GroupForm.create!(form_id: other_form.id, group:)
      end

      it "prints details for each form" do
        expect {
          task.invoke(form.id, other_form.id)
        }.to output(/Form Name: Test Form.*Form Name: Other Form/m).to_stdout
      end
    end

    context "with no arguments" do
      it "aborts with a usage message" do
        expect {
          task.invoke
        }.to raise_error(SystemExit)
               .and output(/usage: rake forms:list_contact_emails/).to_stderr
      end
    end

    context "with an invalid form id" do
      it "raises an error" do
        expect {
          task.invoke("99999")
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "forms:show_exit_pages" do
    subject(:task) do
      Rake::Task["forms:show_exit_pages"]
    end

    let(:form) { create(:form, :ready_for_routing) }
    let(:routing_page) { form.pages.first }
    let(:shown) do
      stdout = StringIO.new
      $stdout = stdout
      task.invoke(form.id)
      JSON.parse(stdout.string)
    ensure
      $stdout = STDOUT
    end
    let(:shown_condition) { shown["pages"].first["routing_conditions"].first }

    it "aborts with a usage message when the form id is missing" do
      expect {
        task.invoke
      }.to raise_error(SystemExit)
             .and output(/usage: rake forms:show_exit_pages\[<form_id>\]/).to_stderr
    end

    it "raises an error when the form does not exist" do
      expect {
        task.invoke("99999")
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    context "when the exit page is stored on the condition and the exit page" do
      let!(:condition) do
        create(:condition, :with_exit_page, routing_page:, check_page: routing_page, exit_page_heading_cy: "Welsh heading", exit_page_markdown_cy: "Welsh markdown")
      end

      it "shows the values stored in both places" do
        stored_values = { "heading" => "Exit page heading", "markdown" => "Exit page markdown", "heading_cy" => "Welsh heading", "markdown_cy" => "Welsh markdown" }

        expect(shown_condition).to include(
          "id" => condition.id,
          "representation" => "both_in_sync",
          "differences" => [],
          "legacy_exit_page_fields" => stored_values,
          "exit_page_id" => condition.exit_page_id,
          "exit_page" => a_hash_including("id" => condition.exit_page_id, **stored_values),
        )
        expect(shown["pages"].first["exit_pages"]).to contain_exactly(a_hash_including("id" => condition.exit_page_id, "condition_ids" => [condition.id]))
        expect(shown["summary"]).to include("representations" => { "both_in_sync" => 1 }, "exit_pages" => 1, "exit_pages_without_conditions" => 0)
      end

      it "shows which values differ when the exit page has been edited directly" do
        condition.exit_page.update!(heading: "Edited heading", markdown_cy: "Edited Welsh markdown")

        expect(shown_condition).to include(
          "representation" => "both_out_of_sync",
          "differences" => %w[heading markdown_cy],
          "legacy_exit_page_fields" => a_hash_including("heading" => "Exit page heading", "markdown_cy" => "Welsh markdown"),
          "exit_page" => a_hash_including("heading" => "Edited heading", "markdown_cy" => "Edited Welsh markdown"),
        )
      end

      it "shows how the exit page is stored in the form documents" do
        form.save_question_changes!

        expect(shown["form_documents"]).to contain_exactly(
          a_hash_including(
            "tag" => "draft",
            "language" => "en",
            "steps" => [
              a_hash_including(
                "id" => routing_page.external_id,
                "routing_conditions" => [a_hash_including("id" => condition.id, "exit_page_id" => condition.exit_page_id, "exit_page_heading" => "Exit page heading")],
                "exit_pages" => [a_hash_including("id" => condition.exit_page_id, "heading" => "Exit page heading")],
              ),
            ],
          ),
        )
      end
    end

    context "when the exit page is only stored on the condition" do
      let!(:condition) { create(:condition, :with_exit_page, routing_page:, check_page: routing_page) }

      before do
        exit_page = condition.exit_page
        condition.update_columns(exit_page_id: nil)
        exit_page.delete
      end

      it "shows the legacy representation" do
        expect(shown_condition).to include("representation" => "legacy_fields_only", "exit_page_id" => nil, "exit_page" => nil)
      end
    end

    context "when the exit page is only stored on the exit page" do
      let(:exit_page) { create(:exit_page, question_page: routing_page) }

      before do
        create(:condition, routing_page:, check_page: routing_page, exit_page:)
      end

      it "shows the exit page model representation" do
        expect(shown_condition).to include(
          "representation" => "exit_page_model_only",
          "legacy_exit_page_fields" => { "heading" => nil, "markdown" => nil, "heading_cy" => nil, "markdown_cy" => nil },
          "exit_page" => a_hash_including("heading" => exit_page.heading),
        )
      end
    end

    context "when the condition is not an exit page" do
      before do
        create(:condition, routing_page:, check_page: routing_page, goto_page: form.pages.last)
        create(:exit_page, question_page: routing_page)
      end

      it "shows that the condition is not an exit page" do
        expect(shown_condition).to include("representation" => "not_an_exit_page")
      end

      it "counts exit pages that no condition goes to" do
        expect(shown["summary"]).to include("exit_pages" => 1, "exit_pages_without_conditions" => 1)
      end
    end
  end

  describe "forms:sync_all_exit_pages" do
    subject(:task) do
      Rake::Task["forms:sync_all_exit_pages"]
    end

    it "creates an exit page object for exit page conditions that are missing one" do
      condition = create(:condition, :with_exit_page)

      condition.exit_page.destroy!

      expect {
        task.invoke
      }.to change(ExitPage, :count).by(1)

      expect(condition.reload.exit_page).to be_present
    end

    it "creates an exit page that has the same properties as the condition's exit page content" do
      condition = create(
        :condition,
        exit_page_heading: "Exit page heading",
        exit_page_markdown: "Exit page markdown",
        exit_page_heading_cy: "Welsh exit page heading",
        exit_page_markdown_cy: "Welsh exit page markdown",
      )

      condition.exit_page.destroy!

      task.invoke

      expect(condition.reload.exit_page.markdown).to eq(condition.exit_page_markdown)
      expect(condition.reload.exit_page.heading).to eq(condition.exit_page_heading)
      expect(condition.reload.exit_page.markdown_cy).to eq(condition.exit_page_markdown_cy)
      expect(condition.reload.exit_page.heading_cy).to eq(condition.exit_page_heading_cy)
    end

    it "does not create an exit page object when one already exists" do
      create(:condition, :with_exit_page)

      expect {
        task.invoke
      }.not_to change(ExitPage, :count)
    end

    it "does not create exit page objects for conditions that are not exit pages" do
      create(:condition)

      expect {
        task.invoke
      }.not_to change(ExitPage, :count)
    end
  end
end
