require "rails_helper"

RSpec.describe Routes::SyncService do
  subject(:service) { described_class.new(form:, routes:) }

  let(:form) { create(:form, pages:) }
  let(:pages) { create_list(:page, 3) }

  let(:routes) { [] }

  describe "#sync_conditions_from_routes" do
    context "when there are no routes" do
      let(:routes) { [] }

      it "does nothing" do
        expect { service.sync_conditions_from_routes }.not_to change(Condition, :count)
        expect(form.conditions.reload).to be_empty
      end
    end

    context "when creating a new condition" do
      let(:routes) do
        [
          build(:route_input, page: pages.first, answer_value: "Yes", goto: GotoValue::Page.new(pages.third.id)),
        ]
      end

      it "creates a new condition for a non-default route" do
        expect { service.sync_conditions_from_routes }.to change(Condition, :count).by(1)

        condition = form.conditions.reload.first
        expect(condition.routing_page_id).to eq(pages.first.id)
        expect(condition.answer_value).to eq("Yes")
        expect(condition.goto_page_id).to eq(pages.third.id)
      end

      it "does not create a condition for a default route" do
        routes.first.goto = GotoValue::DefaultValue.new

        expect { service.sync_conditions_from_routes }.not_to change(Condition, :count)
        expect(form.conditions.reload).to be_empty
      end
    end

    context "when updating an existing condition" do
      # Create an existing condition that will be updated.
      let!(:existing_condition) do
        create(:condition, routing_page_id: pages.first.id, answer_value: "Yes", goto_page_id: pages.second.id)
      end

      # Provide a route that matches the key of the existing condition but has a new destination.
      let(:routes) do
        [
          build(:route_input, page: pages.first, answer_value: "Yes", goto: GotoValue::Page.new(pages.third.id)),
        ]
      end

      it "updates the goto_page_id of the existing condition" do
        # No new conditions should be created or destroyed.
        expect { service.sync_conditions_from_routes }.not_to change(Condition, :count)

        # The existing condition should be updated.
        existing_condition.reload
        expect(existing_condition.goto_page_id).to eq(pages.third.id)
      end
    end

    context "when destroying a stale condition" do
      # Create an existing condition that will now be considered stale.
      let!(:stale_condition) do
        create(:condition, routing_page_id: pages.first.id, answer_value: "Yes", goto_page_id: pages.second.id)
      end

      # Create a condition that shouldn't be removed
      let!(:healthy_condition) do
        create(:condition, routing_page_id: pages.second.id, answer_value: "Yes", goto_page_id: pages.third.id)
      end

      # Provide a route that matches the stale condition's key, but is now a "default" route.
      let(:routes) do
        [
          # Route for the first page, which is default so conditions are removed
          build(:route_input, :default, page: pages.first, answer_value: "Yes"),
          # Two routes for the second page, which should not be removed
          build(:route_input, page: pages.second, goto: GotoValue::Page.new(pages.third.id), answer_value: "Yes"),
          # This is default but has no conditions to remove
          build(:route_input, :default, page: pages.second, answer_value: "No"),
        ]
      end

      it "destroys the condition that is now a default route" do
        expect { service.sync_conditions_from_routes }.to change(Condition, :count).by(-1)
        expect(Condition.exists?(stale_condition.id)).to be false
      end

      it "does not destroy other page's conditions with the same answer value" do
        service.sync_conditions_from_routes
        expect(Condition.exists?(healthy_condition.id)).to be true
      end
    end

    context "with an answer_value of an empty string" do
      let!(:existing_condition) do
        create(:condition, routing_page_id: pages.first.id, answer_value: "", goto_page_id: pages.second.id)
      end

      # The route has an empty string, which .presence converts to nil for the DB lookup.
      let(:routes) do
        [
          build(:route_input, :default, page: pages.first, answer_value: ""), # This should delete the condition
        ]
      end

      it "correctly finds and destroys the condition with a nil answer_value" do
        # This tests that the service correctly finds a condition where the answer_value is persisted as nil
        # (originally from an empty string input) and destroys it.
        # This confirms that `.presence` logic is mirrored in both create and destroy paths.
        existing_condition.update!(answer_value: nil) # Simulate how it's stored in the DB.

        expect { service.sync_conditions_from_routes }.to change(Condition, :count).by(-1)
        expect(Condition.exists?(existing_condition.id)).to be false
      end
    end

    context "with a mix of create, update, and delete operations" do
      # Arrange: Set up a complex initial state
      let!(:condition_to_update) { create(:condition, routing_page_id: pages.first.id, answer_value: "Update Me", goto_page_id: pages.second.id) }
      let!(:condition_to_delete) { create(:condition, routing_page_id: pages.first.id, answer_value: "Delete Me", goto_page_id: pages.second.id) }
      let!(:condition_to_keep) { create(:condition, routing_page_id: pages.second.id, answer_value: "Option A", goto_page_id: pages.third.id) }

      let(:routes) do
        [
          # 1. Update: Matches condition_to_update, but changes goto_page_id to pages.third
          build(:route_input, page: pages.first, answer_value: "Update Me", goto: GotoValue::Page.new(pages.third.id)),

          # 2. Delete: Matches condition_to_delete, but marks it as default
          build(:route_input, :default, page: pages.first, answer_value: "Delete Me"),

          # 3. Create: A brand new condition
          build(:route_input, page: pages.second, answer_value: "Option B", goto: GotoValue::Page.new(pages.first.id)),

          # 4. No-Op: Matches condition_to_keep exactly, no change needed
          build(:route_input, page: pages.second, answer_value: "Option A", goto: GotoValue::Page.new(pages.third.id)),

          # 5. No-Op: A default route with no existing condition
          build(:route_input, :default, page: pages.third, answer_value: "Default"),
        ]
      end

      it "correctly synchronizes all conditions" do
        # We start with 3 conditions. We expect 1 create and 1 delete. Net change is 0.
        expect { service.sync_conditions_from_routes }.not_to change(Condition, :count)

        # Assertions
        # 1. Update was successful
        expect(condition_to_update.reload.goto_page_id).to eq(pages.third.id)

        # 2. Deletion was successful
        expect(Condition.exists?(condition_to_delete.id)).to be false

        # 3. Creation was successful
        new_condition = form.conditions.find_by(routing_page_id: pages.second.id, answer_value: "Option B")
        expect(new_condition).to be_present
        expect(new_condition.goto_page_id).to eq(pages.first.id)

        # 4. Kept condition is untouched
        expect(condition_to_keep.reload).to be_present
      end
    end

    context "when a database error occurs during the transaction" do
      let!(:condition_to_delete) { create(:condition, routing_page_id: pages.first.id, answer_value: "An Existing Answer", goto_page_id: pages.second.id) }

      let(:route_to_succeed) { build(:route_input, :default, page: pages.first, answer_value: "An Existing Answer") }
      let(:route_to_fail) { build(:route_input, page: pages.first, answer_value: "A New Answer", goto: GotoValue::Page.new(pages.third.id)) }
      let(:routes) { [route_to_succeed, route_to_fail] }

      let(:failing_condition_double) { instance_double(Condition) }

      before do
        allow(Condition).to receive(:find_or_initialize_by).and_call_original

        allow(Condition).to receive(:find_or_initialize_by)
          .with(routing_page_id: route_to_fail.page_id, answer_value: route_to_fail.answer_value.presence)
          .and_return(failing_condition_double)

        # We need to allow the `assign_attributes` call
        allow(failing_condition_double).to receive(:assign_attributes)

        # Simulate a failure when `save!` is called
        allow(failing_condition_double).to receive(:save!).and_raise(ActiveRecord::RecordInvalid)
      end

      it "rolls back the transaction, leaving the database unchanged" do
        expect { service.sync_conditions_from_routes }.to raise_error(ActiveRecord::RecordInvalid)

        # It didn't delete the condition that should have been deleted
        expect(condition_to_delete.reload).to be_present
        expect(Condition.exists?(condition_to_delete.id)).to be true
      end
    end
  end
end
