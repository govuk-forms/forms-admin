class Forms::SaveAndReturnInput < BaseInput
  attr_accessor :form, :save_and_return

  validates :save_and_return, presence: true, inclusion: { in: %w[enabled disabled] }

  def submit
    return false if invalid?

    return false if save_and_return_enabled_in_live?

    form.save_and_return = save_and_return
    form.save_draft!
  end

  def assign_form_values
    self.save_and_return = form.save_and_return
    self
  end

  def save_and_return_enabled_in_live?
    # prevents a live form with save and return enabled from being disabled - this is also handled on the frontend
    form.save_and_return == "enabled" &&
      %w[live live_with_draft].include?(form.state)
  end
end
