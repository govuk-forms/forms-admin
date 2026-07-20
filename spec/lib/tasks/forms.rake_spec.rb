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
        expect(form.archived_form_document).not_to be_nil
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

  describe "forms:submission_type:set_to_email" do
    subject(:task) do
      Rake::Task["forms:submission_type:set_to_email"]
    end

    let(:form) do
      create(:form, :live, submission_type: "s3", submission_format: [], delivery_configurations: [
        create(:delivery_configuration, :s3),
        create(:delivery_configuration, :daily_email),
      ])
    end
    let!(:other_form) do
      create(:form, :live, submission_type: "s3", submission_format: [], delivery_configurations: [
        create(:delivery_configuration, :s3),
      ])
    end

    context "when the form is live" do
      it "sets a form's submission_type to email" do
        expect { task.invoke(form.id) }
          .to change { form.reload.submission_type }.to("email")
      end

      it "creates a DeliveryConfiguration for immediate email deliveries and removes the DeliveryConfiguration for s3" do
        task.invoke(form.id)
        expect(form.reload.delivery_configurations.pluck(:delivery_method, :delivery_schedule, :formats)).to contain_exactly(
          ["email", "immediate", []],
          ["email", "daily", %w[csv]],
        )
      end

      it "updates a form's live form document" do
        task.invoke(form.id)
        content = form.live_form_document.reload.content
        expect(content["submission_type"]).to eq("email")
        expect(content["submission_format"]).to eq([])
        expect(content["delivery_configurations"]).to contain_exactly(
          {
            "delivery_method" => "email",
            "delivery_schedule" => "immediate",
            "formats" => [],
          },
          {
            "delivery_method" => "email",
            "delivery_schedule" => "daily",
            "formats" => %w[csv],
          },
        )
      end

      it "updates the form's draft form document" do
        task.invoke(form.id)
        content = form.draft_form_document.reload.content
        expect(content["submission_type"]).to eq("email")
        expect(content["submission_format"]).to eq([])
        expect(content["delivery_configurations"]).to contain_exactly(
          {
            "delivery_method" => "email",
            "delivery_schedule" => "immediate",
            "formats" => [],
          },
          {
            "delivery_method" => "email",
            "delivery_schedule" => "daily",
            "formats" => %w[csv],
          },
        )
      end

      it "does not update a different form" do
        expect { task.invoke(form.id) }
          .not_to(change { other_form.reload.submission_type })
      end
    end

    context "when the form is draft" do
      let(:form) { create :form, submission_type: "s3" }

      it "sets a form's submission_type to email" do
        expect { task.invoke(form.id) }
          .to change { form.reload.submission_type }.to("email")
      end

      it "updates the form's draft form document" do
        task.invoke(form.id)
        expect(form.draft_form_document.reload.content["submission_type"]).to eq("email")
        expect(form.draft_form_document.reload.content["submission_format"]).to eq([])
      end
    end

    context "when the provided submission format is empty" do
      let(:form) { create :form, :live, submission_type: "s3", submission_format: %w[json] }

      it "sets a form's submission format to empty" do
        expect { task.invoke(form.id) }
          .to change { form.reload.submission_format }.to([])
      end

      it "sets a form's submission_type to email" do
        expect { task.invoke(form.id) }
          .to change { form.reload.submission_type }.to("email")
      end
    end

    context "when the provided submission format is email" do
      let(:form) { create :form, :live, submission_type: "s3", submission_format: %w[json] }

      it "sets a form's submission format to empty" do
        expect { task.invoke(form.id, "email") }
          .to change { form.reload.submission_format }.to([])
      end

      it "sets a form's submission_type to email" do
        expect { task.invoke(form.id, "email") }
          .to change { form.reload.submission_type }.to("email")
      end

      it "creates a DeliveryConfiguration with blank format" do
        task.invoke(form.id, "email")
        expect(form.reload.delivery_configurations.pluck(:delivery_method, :delivery_schedule, :formats)).to include(
          ["email", "immediate", []],
        )
      end
    end

    context "when the provided submission format is csv" do
      it "sets a form's submission format to csv" do
        expect { task.invoke(form.id, "csv") }
          .to change { form.reload.submission_format }.to(%w[csv])
      end

      it "sets a form's submission_type to email" do
        expect { task.invoke(form.id, "csv") }
          .to change { form.reload.submission_type }.to("email")
      end

      it "creates a DeliveryConfiguration with csv format" do
        task.invoke(form.id, "csv")
        expect(form.reload.delivery_configurations.pluck(:delivery_method, :delivery_schedule, :formats)).to include(
          ["email", "immediate", %w[csv]],
        )
      end
    end

    context "when the provided submission formate is json" do
      it "sets a form's submission format to json" do
        expect { task.invoke(form.id, "json") }
          .to change { form.reload.submission_format }.to(%w[json])
      end

      it "sets a form's submission_type to email" do
        expect { task.invoke(form.id, "json") }
          .to change { form.reload.submission_type }.to("email")
      end

      it "creates a DeliveryConfiguration with json format" do
        task.invoke(form.id, "json")
        expect(form.reload.delivery_configurations.pluck(:delivery_method, :delivery_schedule, :formats)).to include(
          ["email", "immediate", %w[json]],
        )
      end
    end

    context "when the provided submission format is csv, json" do
      it "sets a form's submission format to csv and json" do
        expect { task.invoke(form.id, "csv", "json") }
          .to change { form.reload.submission_format }.to(%w[csv json])
      end

      it "sets a form's submission_type to email" do
        expect { task.invoke(form.id, "csv", "json") }
          .to change { form.reload.submission_type }.to("email")
      end

      it "creates a DeliveryConfiguration with the provided formats" do
        task.invoke(form.id, "csv", "json")
        expect(form.reload.delivery_configurations.pluck(:delivery_method, :delivery_schedule, :formats)).to include(
          ["email", "immediate", %w[csv json]],
        )
      end
    end

    context "when the provided submission_type is s3" do
      it "aborts with a usage message" do
        expect { task.invoke(form.id, "s3") }
          .to raise_error(SystemExit)
                .and output("submission_format must be one of csv, json\n").to_stderr
      end
    end

    context "without arguments" do
      it "aborts with a usage message" do
        expect {
          task.invoke
        }.to raise_error(SystemExit)
               .and output("usage: rake forms:submission_type:set_to_email[<form_id>(, <submission_format>)*]\n").to_stderr
      end
    end
  end

  describe "forms:submission_type:set_to_s3" do
    subject(:task) do
      Rake::Task["forms:submission_type:set_to_s3"]
    end

    let(:form) do
      create(:form, :with_welsh_translation, :live, delivery_configurations: [
        create(:delivery_configuration, :immediate_email),
        create(:delivery_configuration, :daily_email),
      ])
    end
    let!(:other_form) { create :form, :live }
    let(:s3_bucket_name) { "a-bucket" }
    let(:s3_bucket_aws_account_id) { "an-aws-account-id" }
    let(:s3_bucket_region) { "eu-west-1" }
    let(:format) { "csv" }
    let(:valid_args) { [form.id, s3_bucket_name, s3_bucket_aws_account_id, s3_bucket_region, format] }

    context "when the form is live" do
      context "when the format is csv" do
        it "sets a form's submission_type to s3" do
          expect { task.invoke(*valid_args) }
            .to change { form.reload.submission_type }.to("s3")
        end

        it "sets a form's submission_format to csv" do
          expect { task.invoke(*valid_args) }
            .to change { form.reload.submission_format }.to(%w[csv])
        end

        it "replaces the immediate email DeliveryConfiguration with an s3 configuration" do
          task.invoke(*valid_args)
          expect(form.reload.delivery_configurations.pluck(:delivery_method, :delivery_schedule, :formats)).to contain_exactly(
            ["s3", "immediate", %w[csv]],
            ["email", "daily", %w[csv]],
          )
        end

        it "updates the live form document" do
          task.invoke(*valid_args)
          form_document = form.live_form_document.reload
          expect(form_document.content["submission_type"]).to eq("s3")
          expect(form_document.content["submission_format"]).to eq(%w[csv])
          expect(form_document.content["s3_bucket_name"]).to eq(s3_bucket_name)
          expect(form_document.content["s3_bucket_aws_account_id"]).to eq(s3_bucket_aws_account_id)
          expect(form_document.content["s3_bucket_region"]).to eq(s3_bucket_region)
          expect(form_document.content["delivery_configurations"]).to contain_exactly(
            {
              "delivery_method" => "s3",
              "delivery_schedule" => "immediate",
              "formats" => %w[csv],
            },
            {
              "delivery_method" => "email",
              "delivery_schedule" => "daily",
              "formats" => %w[csv],
            },
          )
        end

        it "updates the live Welsh form document" do
          task.invoke(*valid_args)
          welsh_form_document = form.live_welsh_form_document.reload
          expect(welsh_form_document.content["submission_type"]).to eq("s3")
          expect(welsh_form_document.content["submission_format"]).to eq(%w[csv])
          expect(welsh_form_document.content["s3_bucket_name"]).to eq(s3_bucket_name)
          expect(welsh_form_document.content["s3_bucket_aws_account_id"]).to eq(s3_bucket_aws_account_id)
          expect(welsh_form_document.content["s3_bucket_region"]).to eq(s3_bucket_region)
          expect(welsh_form_document.content["delivery_configurations"]).to contain_exactly(
            {
              "delivery_method" => "s3",
              "delivery_schedule" => "immediate",
              "formats" => %w[csv],
            },
            {
              "delivery_method" => "email",
              "delivery_schedule" => "daily",
              "formats" => %w[csv],
            },
          )
        end

        it "updates the draft form document" do
          task.invoke(*valid_args)
          form_document = form.draft_form_document.reload
          expect(form_document.content["submission_type"]).to eq("s3")
          expect(form_document.content["submission_format"]).to eq(%w[csv])
          expect(form_document.content["s3_bucket_name"]).to eq(s3_bucket_name)
          expect(form_document.content["s3_bucket_aws_account_id"]).to eq(s3_bucket_aws_account_id)
          expect(form_document.content["s3_bucket_region"]).to eq(s3_bucket_region)
          expect(form_document.content["delivery_configurations"]).to contain_exactly(
            {
              "delivery_method" => "s3",
              "delivery_schedule" => "immediate",
              "formats" => %w[csv],
            },
            {
              "delivery_method" => "email",
              "delivery_schedule" => "daily",
              "formats" => %w[csv],
            },
          )
        end
      end

      context "when the format is json" do
        let(:format) { "json" }

        it "sets a form's submission_type to s3" do
          expect { task.invoke(*valid_args) }
            .to change { form.reload.submission_type }.to("s3")
        end

        it "sets a form's submission_format to json" do
          expect { task.invoke(*valid_args) }
            .to change { form.reload.submission_format }.to(%w[json])
        end

        it "replaces the immediate email DeliveryConfiguration with an s3 configuration with json format" do
          task.invoke(*valid_args)
          expect(form.reload.delivery_configurations.pluck(:delivery_method, :delivery_schedule, :formats)).to contain_exactly(
            ["s3", "immediate", %w[json]],
            ["email", "daily", %w[csv]],
          )
        end

        it "updates the live form document" do
          task.invoke(*valid_args)
          form_document = form.live_form_document.reload
          expect(form_document.content["submission_type"]).to eq("s3")
          expect(form_document.content["submission_format"]).to eq(%w[json])
          expect(form_document.content["delivery_configurations"]).to include(
            {
              "delivery_method" => "s3",
              "delivery_schedule" => "immediate",
              "formats" => %w[json],
            },
          )
        end

        it "updates the draft form document" do
          task.invoke(*valid_args)
          form_document = form.draft_form_document.reload
          expect(form_document.content["submission_type"]).to eq("s3")
          expect(form_document.content["submission_format"]).to eq(%w[json])
          expect(form_document.content["delivery_configurations"]).to include(
            {
              "delivery_method" => "s3",
              "delivery_schedule" => "immediate",
              "formats" => %w[json],
            },
          )
        end
      end

      it "sets a form's s3_bucket_name" do
        expect { task.invoke(*valid_args) }
          .to change { form.reload.s3_bucket_name }.to(s3_bucket_name)
      end

      it "sets a form's s3_bucket_aws_account_id" do
        expect { task.invoke(*valid_args) }
          .to change { form.reload.s3_bucket_aws_account_id }.to(s3_bucket_aws_account_id)
      end

      it "sets a form's s3_bucket_region" do
        expect { task.invoke(*valid_args) }
          .to change { form.reload.s3_bucket_region }.to(s3_bucket_region)
      end

      it "does not update a different form" do
        expect { task.invoke(*valid_args) }
          .not_to(change { other_form.reload.submission_type })
      end
    end

    context "when the form is draft" do
      let(:form) { create :form }

      it "updates the draft form document" do
        task.invoke(*valid_args)
        form_document = form.draft_form_document.reload
        expect(form_document.content["submission_type"]).to eq("s3")
        expect(form_document.content["submission_format"]).to eq([format])
        expect(form_document.content["s3_bucket_name"]).to eq(s3_bucket_name)
        expect(form_document.content["s3_bucket_aws_account_id"]).to eq(s3_bucket_aws_account_id)
        expect(form_document.content["s3_bucket_region"]).to eq(s3_bucket_region)
        expect(form_document.content["delivery_configurations"]).to include(
          {
            "delivery_method" => "s3",
            "delivery_schedule" => "immediate",
            "formats" => %w[csv],
          },
        )
      end
    end

    context "without arguments" do
      it "aborts with a usage message" do
        expect {
          task.invoke
        }.to raise_error(SystemExit)
               .and output("usage: rake forms:submission_type:set_to_s3[<form_id>, <s3_bucket_name>, <s3_bucket_aws_account_id>, <s3_bucket_region>, <format>]\n").to_stderr
      end
    end

    context "without bucket name argument" do
      it "aborts with a usage message" do
        expect {
          task.invoke(1)
        }.to raise_error(SystemExit)
               .and output("usage: rake forms:submission_type:set_to_s3[<form_id>, <s3_bucket_name>, <s3_bucket_aws_account_id>, <s3_bucket_region>, <format>]\n").to_stderr
      end
    end

    context "without AWS account ID argument" do
      it "aborts with a usage message" do
        expect {
          task.invoke(1, s3_bucket_name)
        }.to raise_error(SystemExit)
               .and output("usage: rake forms:submission_type:set_to_s3[<form_id>, <s3_bucket_name>, <s3_bucket_aws_account_id>, <s3_bucket_region>, <format>]\n").to_stderr
      end
    end

    context "without region argument" do
      it "aborts with a usage message" do
        expect {
          task.invoke(1, s3_bucket_name, s3_bucket_aws_account_id)
        }.to raise_error(SystemExit)
               .and output("usage: rake forms:submission_type:set_to_s3[<form_id>, <s3_bucket_name>, <s3_bucket_aws_account_id>, <s3_bucket_region>, <format>]\n").to_stderr
      end
    end

    context "without format argument" do
      it "aborts with a usage message" do
        expect {
          task.invoke(1, s3_bucket_name, s3_bucket_aws_account_id, "eu-west-2")
        }.to raise_error(SystemExit)
               .and output("usage: rake forms:submission_type:set_to_s3[<form_id>, <s3_bucket_name>, <s3_bucket_aws_account_id>, <s3_bucket_region>, <format>]\n").to_stderr
      end
    end

    context "when region is not allowed" do
      it "aborts with message" do
        expect {
          task.invoke(1, s3_bucket_name, s3_bucket_aws_account_id, "eu-west-3", "csv")
        }.to raise_error(SystemExit)
               .and output("s3_bucket_region must be one of eu-west-1 or eu-west-2\n").to_stderr
      end
    end

    context "when format is invalid" do
      it "aborts with a usage message" do
        expect {
          task.invoke(1, s3_bucket_name, s3_bucket_aws_account_id, "eu-west-2", "xml")
        }.to raise_error(SystemExit)
               .and output("format must be one of csv or json\n").to_stderr
      end
    end
  end

  describe "forms:show_form_document" do
    subject(:task) do
      Rake::Task["forms:show_form_document"]
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
         .and output(/usage: rake forms:show_form_document\[<form_id>, <tag>, <language>\]/).to_stderr
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
