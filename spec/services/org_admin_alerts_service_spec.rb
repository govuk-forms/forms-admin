require "rails_helper"

RSpec.describe OrgAdminAlertsService do
  subject(:service) { described_class.new(form:, current_user:) }

  let(:organisation) { create(:organisation, :with_signed_mou) }
  let(:group) { create(:group, organisation:, status: :active) }
  let(:current_user) { create(:organisation_admin_user, organisation:) }
  let!(:organisation_admins) { create_list(:organisation_admin_user, 2, organisation:) }

  before do
    GroupForm.create!(form: form, group:)
    form.set_task_status_service(TaskStatusService.new(form:))
  end

  describe "#form_made_live" do
    let(:form) { create(:form, :ready_for_live, state: previous_state) }

    before do
      form.make_live! unless form.live?
    end

    context "when the previous state is draft" do
      let(:previous_state) { :draft }

      context "when form was not copied from another form" do
        it "sends the new draft form made live email to the organisation admins" do
          expect(AdminAlerts::MadeLiveMailer).to receive(:new_draft_form_made_live).with(
            form: form,
            user: current_user,
            to_email: organisation_admins.first.email,
          ).and_call_original

          expect(AdminAlerts::MadeLiveMailer).to receive(:new_draft_form_made_live).with(
            form: form,
            user: current_user,
            to_email: organisation_admins.second.email,
          ).and_call_original

          service.form_made_live

          expect(ActionMailer::Base.deliveries.size).to eq(2)
        end

        it "does not send an email to the current user" do
          allow(AdminAlerts::MadeLiveMailer).to receive(:new_draft_form_made_live).and_call_original
          service.form_made_live

          expect(AdminAlerts::MadeLiveMailer).not_to have_received(:new_draft_form_made_live).with(
            form: form,
            user: current_user,
            to_email: current_user.email,
          )
        end
      end

      context "when form was copied from another form" do
        let(:copied_from_form) { create(:form, :ready_for_live) }
        let(:form) { create(:form, :ready_for_live, state: previous_state, copied_from_id: copied_from_form.id) }

        it "sends the copied form made live email to the organisation admins" do
          expect(AdminAlerts::MadeLiveMailer).to receive(:copied_form_made_live).with(
            form: form,
            copied_from_form: copied_from_form,
            user: current_user,
            to_email: organisation_admins.first.email,
          ).and_call_original

          expect(AdminAlerts::MadeLiveMailer).to receive(:copied_form_made_live).with(
            form: form,
            copied_from_form: copied_from_form,
            user: current_user,
            to_email: organisation_admins.second.email,
          ).and_call_original

          service.form_made_live

          expect(ActionMailer::Base.deliveries.size).to eq(2)
        end
      end
    end

    context "when the previous state is live with draft" do
      let(:previous_state) { :live_with_draft }

      it "sends the live form changes made live email to the organisation admins" do
        expect(AdminAlerts::MadeLiveMailer).to receive(:live_form_changes_made_live).with(
          form: form,
          user: current_user,
          to_email: organisation_admins.first.email,
        ).and_call_original

        expect(AdminAlerts::MadeLiveMailer).to receive(:live_form_changes_made_live).with(
          form: form,
          user: current_user,
          to_email: organisation_admins.second.email,
        ).and_call_original

        service.form_made_live

        expect(ActionMailer::Base.deliveries.size).to eq(2)
      end
    end

    context "when the previous state is archived" do
      let(:previous_state) { :archived }

      it "sends the archived form made live email to the organisation admins" do
        expect(AdminAlerts::MadeLiveMailer).to receive(:archived_form_made_live).with(
          form: form,
          user: current_user,
          to_email: organisation_admins.first.email,
        ).and_call_original

        expect(AdminAlerts::MadeLiveMailer).to receive(:archived_form_made_live).with(
          form: form,
          user: current_user,
          to_email: organisation_admins.second.email,
        ).and_call_original

        service.form_made_live

        expect(ActionMailer::Base.deliveries.size).to eq(2)
      end
    end

    context "when the previous state is archived with draft" do
      let(:previous_state) { :archived_with_draft }

      it "sends the archived form changes made live email to the organisation admins" do
        expect(AdminAlerts::MadeLiveMailer).to receive(:archived_form_changes_made_live).with(
          form: form,
          user: current_user,
          to_email: organisation_admins.first.email,
        ).and_call_original

        expect(AdminAlerts::MadeLiveMailer).to receive(:archived_form_changes_made_live).with(
          form: form,
          user: current_user,
          to_email: organisation_admins.second.email,
        ).and_call_original

        service.form_made_live

        expect(ActionMailer::Base.deliveries.size).to eq(2)
      end
    end

    context "when the previous state is unexpected" do
      let(:previous_state) { :live }

      it "raises an error and does not send any emails" do
        expect {
          service.form_made_live
        }.to raise_error(StandardError, "Unexpected previous state: live")

        expect(ActionMailer::Base.deliveries.size).to eq(0)
      end
    end
  end

  describe "#new_draft_form_created" do
    let(:form) { create(:form) }

    context "when form was not copied from another form" do
      it "sends the new draft form created email to the organisation admins" do
        expect(AdminAlerts::DraftCreatedMailer).to receive(:new_draft_form_created).with(
          form: form,
          user: current_user,
          to_email: organisation_admins.first.email,
        ).and_call_original

        expect(AdminAlerts::DraftCreatedMailer).to receive(:new_draft_form_created).with(
          form: form,
          user: current_user,
          to_email: organisation_admins.second.email,
        ).and_call_original

        service.new_draft_form_created

        expect(ActionMailer::Base.deliveries.size).to eq(2)
      end

      it "does not send an email to the current user" do
        allow(AdminAlerts::DraftCreatedMailer).to receive(:new_draft_form_created).and_call_original
        service.new_draft_form_created

        expect(AdminAlerts::DraftCreatedMailer).not_to have_received(:new_draft_form_created).with(
          form: form,
          user: current_user,
          to_email: current_user.email,
        )
      end
    end

    context "when form was copied from another form" do
      let(:copied_from_form) { create(:form, :ready_for_live) }
      let(:form) { create(:form, :ready_for_live, copied_from_id: copied_from_form.id) }

      it "sends the copied draft form created email to the organisation admins" do
        expect(AdminAlerts::DraftCreatedMailer).to receive(:copied_draft_form_created).with(
          form: form,
          copied_from_form: copied_from_form,
          user: current_user,
          to_email: organisation_admins.first.email,
        ).and_call_original

        expect(AdminAlerts::DraftCreatedMailer).to receive(:copied_draft_form_created).with(
          form: form,
          copied_from_form: copied_from_form,
          user: current_user,
          to_email: organisation_admins.second.email,
        ).and_call_original

        service.new_draft_form_created

        expect(ActionMailer::Base.deliveries.size).to eq(2)
      end
    end

    context "when the group is not active" do
      before do
        group.trial!
      end

      it "does not send any emails" do
        service.new_draft_form_created

        expect(ActionMailer::Base.deliveries.size).to eq(0)
      end
    end
  end

  describe "#draft_of_existing_form_created" do
    context "when the form state is live with draft" do
      let(:form) { create(:form, :live_with_draft) }

      it "sends the live form changes made live email to the organisation admins" do
        expect(AdminAlerts::DraftCreatedMailer).to receive(:new_live_form_draft_created).with(
          form: form,
          user: current_user,
          to_email: organisation_admins.first.email,
        ).and_call_original

        expect(AdminAlerts::DraftCreatedMailer).to receive(:new_live_form_draft_created).with(
          form: form,
          user: current_user,
          to_email: organisation_admins.second.email,
        ).and_call_original

        service.draft_of_existing_form_created

        expect(ActionMailer::Base.deliveries.size).to eq(2)
      end

      it "does not send an email to the current user" do
        allow(AdminAlerts::DraftCreatedMailer).to receive(:new_live_form_draft_created).and_call_original
        service.draft_of_existing_form_created

        expect(AdminAlerts::DraftCreatedMailer).not_to have_received(:new_live_form_draft_created).with(
          form: form,
          user: current_user,
          to_email: current_user.email,
        )
      end
    end

    context "when the form state is archived with draft" do
      let(:form) { create(:form, :archived_with_draft) }

      it "sends the archived form changes made live email to the organisation admins" do
        expect(AdminAlerts::DraftCreatedMailer).to receive(:new_archived_form_draft_created).with(
          form: form,
          user: current_user,
          to_email: organisation_admins.first.email,
        ).and_call_original

        expect(AdminAlerts::DraftCreatedMailer).to receive(:new_archived_form_draft_created).with(
          form: form,
          user: current_user,
          to_email: organisation_admins.second.email,
        ).and_call_original

        service.draft_of_existing_form_created

        expect(ActionMailer::Base.deliveries.size).to eq(2)
      end
    end

    context "when the form state is unexpected" do
      let(:form) { create(:form) }

      it "raises an error and does not send any emails" do
        expect {
          service.draft_of_existing_form_created
        }.to raise_error(StandardError, "Unexpected form state: draft")

        expect(ActionMailer::Base.deliveries.size).to eq(0)
      end
    end
  end
end
