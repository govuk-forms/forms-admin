class FormDocumentSyncService
  attr_reader :form

  DRAFT_TAG = "draft".freeze
  LIVE_TAG = "live".freeze
  ARCHIVED_TAG = "archived".freeze

  def initialize(form)
    @form = form
  end

  def synchronize_live_form
    FormDocument.transaction do
      # A new live version replaces any previous archived version
      delete_form_documents_by_tag(ARCHIVED_TAG)

      synchronize_documents_for_tag(LIVE_TAG, live_at: form.updated_at)
    end
  end

  def synchronize_archived_form
    FormDocument.transaction do
      # Ensure we only archive forms that are currently live
      raise ActiveRecord::RecordNotFound, "Cannot archive a form that has no live version." unless live_documents.exists?

      # Change all live documents to archived
      live_documents.update_all(tag: ARCHIVED_TAG)
    end
  end

  def synchronize_archived_welsh_form
    FormDocument.transaction do
      raise ActiveRecord::RecordNotFound, "Cannot archive a form that has no live version." unless form.has_live_welsh_translation?

      welsh_form_document = form.latest_welsh_form_document
      welsh_form_document.update!(tag: ARCHIVED_TAG)

      draft_form_document = form.draft_form_document
      draft_form_document.content["available_languages"].delete("cy")
      draft_form_document.save!

      english_content = form.latest_form_document.content
      english_content["available_languages"] = %w[en]
      create_new_versioned_form_document(LIVE_TAG, english_content, "en", version_number_of_existing_form_document + 1)

      form.update_columns(available_languages: %w[en], welsh_completed: false)
    end
  end

  def synchronize_only_live_english_form
    FormDocument.transaction do
      # If we've already made the Welsh version live, changes to the Welsh version must be made live at the same time by calling a different method
      raise ActiveRecord::RecordNotFound, "Cannot make changes to only the live English form if there is already a live Welsh version." if form.has_live_welsh_translation?

      # A new live version replaces any previous archived version
      delete_form_documents_by_tag(ARCHIVED_TAG)

      content = form_content("en", live_at: form.updated_at)
      content["available_languages"] = %w[en] # don't include Welsh in available languages
      create_new_versioned_form_document(LIVE_TAG, content, "en", version_number_of_existing_form_document + 1)
    end
  end

  def synchronize_only_live_welsh_form
    FormDocument.transaction do
      english_form_document = form.latest_form_document

      # Ensure we only make Welsh version live if there is already an existing live English version
      raise ActiveRecord::RecordNotFound, "Cannot make Welsh version live unless there is already a live English version." unless english_form_document&.tag == LIVE_TAG

      # A new live version replaces the archived version
      delete_form_documents_by_tag(ARCHIVED_TAG)

      content = form_content("cy", live_at: form.updated_at)
      new_version_number = english_form_document.version + 1

      create_new_versioned_form_document(LIVE_TAG, content, "cy", new_version_number)

      # Create a new live English form document with the available languages updated
      english_content = english_form_document.content
      english_content["available_languages"] = %w[en cy]
      create_new_versioned_form_document(LIVE_TAG, english_content, "en", new_version_number)
    end
  end

  def update_draft_form_document
    synchronize_documents_for_tag(DRAFT_TAG)
  end

private

  # Create/update documents for all languages for a specific tag
  def synchronize_documents_for_tag(tag, **content_options)
    version = tag == DRAFT_TAG ? nil : version_number_of_existing_form_document + 1

    FormDocument.transaction do
      form.normalise_welsh!
      form.available_languages.each do |language|
        content = form_content(language, **content_options)
        update_or_create_form_document(tag, content, language, version)
      end

      # Clean up any documents for languages no longer used by the form
      delete_form_documents_for_unused_languages(tag)
    end
  end

  def update_or_create_form_document(tag, content, language, version)
    if tag == DRAFT_TAG
      update_or_create_draft_form_document(content, language)
    else
      create_new_versioned_form_document(tag, content, language, version)
    end
  end

  def update_or_create_draft_form_document(content, language)
    form_document = FormDocument.find_or_initialize_by(
      form_id: form.id,
      tag: DRAFT_TAG,
      language:,
    )
    form_document.content = content

    form_document.save!
  end

  def create_new_versioned_form_document(tag, content, language, version)
    form_document = FormDocument.new(
      form_id: form.id,
      tag:,
      language:,
      content:,
      version:,
    )

    form_document.save!

    # use update_column to skip callbacks so we don't sync the draft form document again
    form.update_column(:latest_form_document_id, form_document.id) if language == "en" && tag == LIVE_TAG
  end

  def delete_form_documents_by_tag(tag)
    form_documents_by_tag(tag).delete_all
  end

  def delete_form_documents_for_unused_languages(tag)
    form_documents_by_tag(tag)
      .where.not(language: form.available_languages)
      .delete_all
  end

  def form_documents_by_tag(tag)
    FormDocument.where(form:, tag:)
  end

  def live_documents
    form_documents_by_tag(LIVE_TAG)
  end

  def form_content(language, **options)
    Mobility.with_locale(language) do
      form.as_form_document(language:, **options)
    end
  end

  def version_number_of_existing_form_document
    form.latest_form_document&.version || 0
  end
end
