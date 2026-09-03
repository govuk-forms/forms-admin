class Forms::DeleteWelshTranslationInput < DeleteConfirmationInput
  attr_accessor :form

  def submit
    return false if invalid?

    reset_translations if confirmed?
    true
  end

  def submit_without_confirm
    reset_translations
    true
  end

private

  def reset_translations
    reset_form_translations
    reset_page_translations
    reset_condition_translations
    reset_exit_page_translations
  end

  def reset_form_translations
    clear_translated_fields(Form, form)
    form.translations.where(locale: :cy).delete_all
    form.available_languages = %w[en]
    form.welsh_completed = false
    form.save_draft!
  end

  def reset_page_translations
    Page::Translation.where(locale: :cy, page_id: form.page_ids).delete_all
  end

  def reset_condition_translations
    Condition::Translation.where(locale: :cy, condition_id: form.condition_ids).delete_all
  end

  def reset_exit_page_translations
    ExitPage::Translation.where(locale: :cy, exit_page_id: form.exit_page_ids).delete_all
  end

  def clear_translated_fields(model, object)
    model.mobility_attributes.each do |attribute|
      object.public_send("#{attribute}_cy=", nil)
    end
    object.save!
  end
end
