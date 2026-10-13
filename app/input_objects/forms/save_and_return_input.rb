class Forms::SaveAndReturnInput < BaseInput
  attr_accessor :form, :save_and_return

  validates :save_and_return, presence: true, inclusion: { in: %w[enabled disabled] }

  def submit
    return false if invalid?

    form.save_and_return = save_and_return
    form.save_draft!
  end

  def assign_form_values
    self.save_and_return = form.save_and_return
    self
  end
end
