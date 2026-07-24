class MouSignaturesController < WebController
  before_action :set_agreement_type

  def show
    @mou_signature = current_user.current_organisation_mou_signature
    redirect_to new_path if @mou_signature.nil?

    # redirect if the path is not for the agreement type the user has signed
    redirect_to show_path unless request.path == show_path
  end

  def new
    return redirect_to show_path if already_signed?

    @mou_signature = MouSignature.new
  end

  def create
    @mou_signature = MouSignature.new(mou_signature_params)
    @mou_signature.user = current_user
    @mou_signature.organisation = current_user.organisation
    @mou_signature.agreement_type = @agreement_type

    if @mou_signature.save
      redirect_to confirmation_path
    else
      render(:new, status: :unprocessable_content)
    end
  rescue ActiveRecord::RecordNotUnique
    render(:new, status: :unprocessable_content)
  end

  def confirmation
    redirect_to new_path unless already_signed?
  end

private

  def mou_signature_params
    params.require(:mou_signature).permit(:agreed)
  end

  def already_signed?
    current_user.has_signed_current_organisation_mou?
  end

  def set_agreement_type
    @agreement_type = params.require(:agreement_type).to_sym
    @create_path = create_path
  end

  def new_path
    @agreement_type == :crown ? new_mou_signature_path : new_non_crown_agreement_signature_path
  end

  def show_path
    # if they've already signed, show them the correct page regardless of the URL they visited
    existing_signature = current_user.current_organisation_mou_signature
    agreement_type = existing_signature&.agreement_type&.to_sym || @agreement_type

    agreement_type == :crown ? mou_signature_path : non_crown_agreement_signature_path
  end

  def create_path
    @agreement_type == :crown ? mou_signature_path : non_crown_agreement_signature_path
  end

  def confirmation_path
    @agreement_type == :crown ? confirmation_mou_signature_path : confirmation_non_crown_agreement_signature_path
  end
end
