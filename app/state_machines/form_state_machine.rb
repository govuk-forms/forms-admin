module FormStateMachine
  extend ActiveSupport::Concern

  included do
    include AASM

    enum :state, {
      draft: "draft",
      deleted: "deleted",
      live: "live",
      live_with_draft: "live_with_draft",
      archived: "archived",
      archived_with_draft: "archived_with_draft",
    }

    aasm column: :state, enum: true, whiny_persistence: true do
      state :draft, initial: true
      state :deleted, :live, :live_with_draft, :archived, :archived_with_draft

      # May be able to remove this as we haven't been using it in the API
      event :delete_form do
        after do
          destroy!
        end

        transitions from: :draft, to: :deleted
      end

      event :make_live do
        before :before_make_live
        after :after_make_live

        transitions from: %i[draft live_with_draft archived archived_with_draft], to: :live, guard: :ready_for_live
      end

      event :make_english_version_live do
        before :before_make_english_live
        after :after_make_english_live

        transitions from: %i[draft live live_with_draft], to: :live, guard: :can_make_english_version_live?
      end

      event :make_welsh_version_live do
        before :before_make_welsh_live
        after :after_make_welsh_live

        transitions from: %i[live live_with_draft], to: :live, guard: :can_make_welsh_version_live?
      end

      event :create_draft_from_live_form do
        after :after_create_draft

        transitions from: :live, to: :live_with_draft
      end

      event :create_draft_from_archived_form do
        after :after_create_draft

        transitions from: :archived, to: :archived_with_draft
      end

      event :archive_live_form do
        after :after_archive

        transitions from: :live, to: :archived
        transitions from: :live_with_draft, to: :archived_with_draft
      end

      event :delete_draft_from_live_form do
        transitions from: %i[live_with_draft live], to: :live
      end

      event :delete_draft_from_archived_form do
        transitions from: %i[archived_with_draft archived], to: :archived
      end
    end
  end
end
