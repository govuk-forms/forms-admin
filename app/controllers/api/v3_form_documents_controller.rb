class Api::V3FormDocumentsController < ApplicationController
  def show
    form_document = form.form_documents.find_by!(version: version, language: language)

    CurrentLoggingAttributes.form_document_version = form_document.version

    render json: form_document.content.merge("version" => form_document.version)
  end

  def draft
    form_document = form.form_documents.find_by!(version: nil, language: language)

    CurrentLoggingAttributes.form_document_version = "draft"

    render json: form_document.content.merge("version" => nil)
  end

  def live
    return head :gone if form.is_archived?

    return_latest_version_number
  end

  def archived
    raise NotFoundError unless form.is_archived?

    return_latest_version_number
  end

  def delivery_configurations
    return draft_delivery_configurations if state == "draft"

    current_delivery_configurations
  end

private

  def return_latest_version_number
    latest_form_document = form.latest_form_document || (raise NotFoundError)

    CurrentLoggingAttributes.form_document_version = latest_form_document.version

    render json: { version: latest_form_document.version }.to_json
  end

  def form
    @form ||= Form.find(form_id)
  end

  def version
    params.require(:version)
  end

  def language
    permitted = params.permit(:language)
    permitted[:language] || "en"
  end

  def form_id
    params.require(:form_id)
  end

  def state
    params.require(:state)
  end

  def draft_delivery_configurations
    raise NotFoundError unless form.has_draft_version

    render json: form.draft_form_document.content["delivery_configurations"]
  end

  def current_delivery_configurations
    raise NotFoundError unless form.is_live? || form.is_archived?

    render json: form.latest_form_document.content["delivery_configurations"]
  end
end
