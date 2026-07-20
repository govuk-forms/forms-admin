# This service reverts a draft form to a form_document with a given tag,
# effectively discarding all draft changes
class RevertDraftFormService
  attr_reader :form

  # A list of attributes on the Form model that should be not be reverted
  FORM_ATTRIBUTES_TO_PRESERVE = %i[id created_at updated_at creator_id].freeze
  ATTRIBUTES_TO_EXCLUDE = Form::ATTRIBUTES_NOT_IN_FORM_DOCUMENT + FORM_ATTRIBUTES_TO_PRESERVE

  def initialize(form)
    @form = form
  end

  # Discards draft changes by reverting the form and its associations
  # to the state of the form_document with the given tag
  # Returns true on success, false on failure
  def revert_draft_from_form_document(tag)
    # Return early if there's no draft to discard
    form_document = FormDocument.find_by(form_id: form.id, tag:, language: "en")
    return false if form_document.blank?

    form_document_content = form_document.content

    ActiveRecord::Base.transaction do
      revert_form_attributes(form_document_content)
      revert_pages_and_nested_associations(form_document_content["steps"])
      revert_delivery_configurations(form_document_content)
      if welsh_form_document_exists?(tag)
        revert_welsh_translations(tag)
      else
        clear_welsh_translations
      end

      if tag == :live
        form.delete_draft_from_live_form
      elsif tag == :archived
        form.delete_draft_from_archived_form
      end

      form.save!
    end

    true
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("Failed to discard draft for form #{form.id}: #{e.message}")
    false
  end

private

  # revert the top-level attributes of the Form object
  def revert_form_attributes(form_document_content)
    attributes_to_update = Form.attribute_names - ATTRIBUTES_TO_EXCLUDE.map(&:to_s)

    form.assign_attributes(form_document_content.slice(*attributes_to_update))
  end

  def revert_pages_and_nested_associations(steps_data)
    form.pages.reload

    revert_pages(steps_data)

    # revert conditions after pages are created to make sure conditions don't
    # have validation errors if the page hasn't been created yet
    revert_routing_conditions(steps_data)
  end

  def revert_pages(steps_data)
    form_document_step_ids = steps_data.pluck("id")

    # delete any pages on the form that are not present in the form_document version
    form.pages.where.not(external_id: form_document_step_ids).destroy_all

    # iterate through the form_document steps data to create or update pages using the external ID
    steps_data.each do |step_data|
      page = form.pages.find_or_initialize_by(external_id: step_data["id"])

      assign_page_attributes(page, step_data)

      page.save!
    end
  end

  # steps in a form_document store the page attributes under "data"
  def assign_page_attributes(page, step_data)
    page_data = step_data["data"]
    page.assign_attributes(
      position: step_data["position"],
      question_text: page_data["question_text"],
      hint_text: page_data["hint_text"],
      answer_type: page_data["answer_type"],
      is_optional: page_data["is_optional"],
      answer_settings: page_data["answer_settings"],
      page_heading: page_data["page_heading"],
      guidance_markdown: page_data["guidance_markdown"],
      is_repeatable: page_data["is_repeatable"],
    )
  end

  def revert_routing_conditions(steps_data)
    all_conditions_data = steps_data.flat_map { |step| step["routing_conditions"] || [] }
    form_document_condition_ids = all_conditions_data.pluck("id")

    # remove any conditions which have been added to the draft but are not in the form_document data
    form.conditions.where.not(id: form_document_condition_ids).destroy_all

    all_conditions_data.each do |condition_data|
      condition = Condition.find_or_initialize_by(id: condition_data["id"])

      assign_condition_attributes(condition, condition_data)
      condition.save!
    end
  end

  def assign_condition_attributes(condition, condition_data)
    condition.answer_value = condition_data["answer_value"]
    condition.routing_page = Page.find_by!(external_id: condition_data["routing_page_id"]) if condition_data["routing_page_id"]
    condition.check_page = Page.find_by!(external_id: condition_data["check_page_id"]) if condition_data["check_page_id"]
    condition.goto_page = Page.find_by!(external_id: condition_data["goto_page_id"]) if condition_data["goto_page_id"]
  end

  def welsh_form_document_exists?(tag)
    FormDocument.exists?(form_id: form.id, tag:, language: "cy")
  end

  def revert_welsh_translations(tag)
    welsh_form_document = FormDocument.find_by(form_id: form.id, tag:, language: "cy")
    return if welsh_form_document.blank?

    welsh_content = welsh_form_document.content

    # Revert form-level Welsh translations
    revert_form_welsh_attributes(welsh_content)

    # Revert page-level Welsh translations
    revert_pages_welsh_attributes(welsh_content["steps"])

    # Revert condition-level Welsh translations
    revert_conditions_welsh_attributes(welsh_content["steps"])
  end

  def revert_form_welsh_attributes(welsh_content)
    Form.mobility_attributes.each do |attr|
      welsh_value = welsh_content[attr]
      form.public_send("#{attr}_cy=", welsh_value) if welsh_content.key?(attr)
    end
  end

  def revert_pages_welsh_attributes(steps_data)
    return if steps_data.blank?

    steps_data.each do |step_data|
      page = form.pages.find_by(external_id: step_data["id"])
      next if page.blank?

      page_data = step_data["data"]
      next if page_data.blank?

      # Revert Welsh translations for page attributes
      Page.mobility_attributes.each do |attr|
        page.public_send("#{attr}_cy=", page_data[attr]) if page_data.key?(attr)
      end

      page.save!
    end
  end

  def revert_conditions_welsh_attributes(steps_data)
    return if steps_data.blank?

    all_conditions_data = steps_data.flat_map { |step| step["routing_conditions"] || [] }

    all_conditions_data.each do |condition_data|
      condition = Condition.find_by(id: condition_data["id"])
      next if condition.blank?

      # Revert Welsh translations for condition attributes
      Condition.mobility_attributes.each do |attr|
        condition.public_send("#{attr}_cy=", condition_data[attr]) if condition_data.key?(attr)
      end

      condition.save!
    end
  end

  def clear_welsh_translations
    # Delete Welsh translations directly from the database using Mobility's translations association
    form.translations.where(locale: :cy).delete_all
    Page::Translation.where(locale: :cy, page_id: form.page_ids).delete_all
    Condition::Translation.where(locale: :cy, condition_id: form.condition_ids).delete_all
  end

  def revert_delivery_configurations(form_document_content)
    delivery_configurations_data = form_document_content["delivery_configurations"] || []

    form.delivery_configurations.destroy_all
    delivery_configurations_data.each do |delivery_configuration|
      form.delivery_configurations.create!(delivery_configuration.slice("delivery_method", "formats", "delivery_schedule"))
    end
  end
end
