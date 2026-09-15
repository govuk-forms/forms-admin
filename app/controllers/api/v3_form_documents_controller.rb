class Api::V3FormDocumentsController < ApplicationController
  def show
    # we are switching to storing the form version on the submission,
    # as a fallback we need to keep using the form document version until all submissions without a version have been deleted
    form_document = form.form_documents.find_by!(version: version, language: language)
    version = form.try(:form_version) || form_document.version

    CurrentLoggingAttributes.form_document_version = version

    render json: form_document.content.merge("version" => version)
  end

  def draft
    form_document = form.form_documents.find_by!(version: nil, language: language)

    CurrentLoggingAttributes.form_document_version = "draft"

    render json: form_document.content.merge("version" => nil)
  end

  def live
    return head :gone if form.is_archived?

    redirect_to_version
  end

  def archived
    raise NotFoundError unless form.is_archived?

    redirect_to_version
  end

private

  def redirect_to_version
    latest_form_document = form.latest_form_document || (raise NotFoundError)

    CurrentLoggingAttributes.form_document_version = latest_form_document.version

    redirect_to api_v3_form_document_version_url(form_id: form_id, version: latest_form_document.version)
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
end
