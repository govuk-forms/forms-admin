class Forms::SubmissionEmailInput < BaseInput
  attr_accessor :form, :temporary_submission_email, :email_code, :confirmation_code, :current_user, :notify_response_id

  validates :temporary_submission_email, presence: true
  validates :temporary_submission_email, email_address: { message: :invalid_email }
  validates :temporary_submission_email, allowed_email_domain: true

  EMAIL_CODE_REGEX = /[0-9]{6}/
  validates :email_code, format: { with: EMAIL_CODE_REGEX, message: :invalid_email_code }, if: -> { email_code.present? }
  validate :email_code_matches_confirmation_code

  def submit
    return false if invalid?

    confirmation_code = generate_confirmation_code

    form_submission_email = FormSubmissionEmail.find_by_form_id(form.id)

    form_processed = if form_submission_email.nil?
                       create_submission_email_record(confirmation_code)
                     else
                       update_submission_email_record(confirmation_code, form_submission_email)
                     end

    if form_processed && temporary_submission_email.present?
      # send notify email?
      Rails.logger.info "Email sent to #{temporary_submission_email} with code #{confirmation_code}"
      SubmissionEmailMailer.send_confirmation_code(
        new_submission_email: temporary_submission_email,
        form_name: form.name,
        confirmation_code:,
        notify_response_id:,
        current_user:,
      ).deliver_now
      true
    else
      false
    end
  end

  def confirm_confirmation_code
    return false if invalid?

    # Update the submission email in the form
    form.submission_email = temporary_submission_email
    form.delivery_configurations.find_or_create_by!(delivery_method: :email, delivery_schedule: :immediate)
    form.save_draft!
    mark_submission_email_as_confirmed
  end

  def mark_submission_email_as_confirmed
    self.confirmation_code = nil
    form_submission_email = FormSubmissionEmail.find_by_form_id(form.id)
    form_submission_email.update!(confirmation_code: nil, updated_by_name: current_user.name, updated_by_email: current_user.email)
  end

  def assign_form_values
    form_submission_email = FormSubmissionEmail.find_by_form_id(form.id)

    if form_submission_email.nil?
      self.temporary_submission_email = form.submission_email
    else
      self.temporary_submission_email = form_submission_email.temporary_submission_email
      self.confirmation_code = form_submission_email.confirmation_code
    end

    self.notify_response_id ||= SecureRandom.uuid

    self
  end

private

  def generate_confirmation_code
    SecureRandom.random_number(10**6).to_s.rjust(6, "0")
  end

  def email_code_matches_confirmation_code
    if confirmation_code.present? && email_code != confirmation_code
      errors.add(:email_code, :email_code_mismatch)
    end
  end

  def create_submission_email_record(confirmation_code)
    FormSubmissionEmail.create!(form_id: form.id,
                                temporary_submission_email:,
                                confirmation_code:,
                                created_by_name: current_user.name,
                                created_by_email: current_user.email)
  end

  def update_submission_email_record(confirmation_code, form)
    form.update(temporary_submission_email:,
                confirmation_code:,
                updated_by_name: current_user.name,
                updated_by_email: current_user.email)
  end
end
