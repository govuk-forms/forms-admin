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

private

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
end
