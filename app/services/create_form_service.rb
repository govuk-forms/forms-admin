class CreateFormService
  class CreateFormEvent < ApplicationRecord
    belongs_to :user
    belongs_to :group
  end

  def create!(creator:, group:, name:)
    event = begin
      CreateFormEvent.create!(group:, form_name: name, user: creator, dedup_version: 1)
    rescue ActiveRecord::RecordNotUnique
      # If a form with the same name in the same group was created by the same
      # user less than a second ago, assume that this was a duplicate request
      # and return the form ID of the previously created form
      previous_event = CreateFormEvent.order(created_at: :desc).find_by(group:, form_name: name)

      # We might need to wait for the form to be created by the previous request
      if previous_event.user == creator && previous_event.created_at > 1.second.ago
        timeout_message = "CreateFormService#create! timed out waiting for form to be created by previous invocation: " \
          "did something go wrong with creating form '#{name}' in group #{group.id} by user #{creator.id}?"

        Timeout.timeout(1, nil, timeout_message) do
          while previous_event.form_id.blank?
            sleep(0.01)
            previous_event.reload
          end
        end

        previous_event
      else
        CreateFormEvent.create!(group:, form_name: name, user: creator, dedup_version: previous_event.dedup_version + 1)
      end
    end

    if event.form_id.present?
      form = Form.find(event.form_id)
    else
      form = Form.create!(creator_id: creator.id, name:, brand_id: default_brand_id(group))
      GroupForm.create!(group:, form_id: form.id)
      event.update!(form_id: form.id)
    end

    form
  end

private

  def default_brand_id(group)
    return nil unless FeatureService.new(group:).enabled?(:custom_branding)

    group.organisation.default_brand&.slug
  end
end
