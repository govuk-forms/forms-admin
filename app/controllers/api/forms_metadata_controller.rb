class Api::FormsMetadataController < ApplicationController
  def group
    render json: Form.find_by!(id: form_id).group
  end

  def form_id
    params.require(:form_id)
  end
end
