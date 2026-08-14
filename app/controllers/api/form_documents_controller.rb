class Api::FormDocumentsController < ApplicationController
  def show
    render json: form_document.content
  end

  def group
    render json: Form.find_by!(id: form_id).group
  end

private

  def form_document
    form_id, tag, language = form_document_params.values_at(:form_id, :tag, :language)

    return FormDocument.find_by!(form_id:, tag:, language:) if tag == "draft"

    latest_form_document = FormDocument.latest_live_or_archived(form_id:, language:)

    raise NotFoundError unless latest_form_document&.tag == tag

    CurrentLoggingAttributes.form_document_version = latest_form_document&.version

    latest_form_document
  end

  def form_document_params
    permitted_params = params.permit(:form_id, :tag, :language)

    # default language to "en" if not given
    permitted_params[:language] ||= "en"

    permitted_params
  end

  def form_id
    params.require(:form_id)
  end
end
