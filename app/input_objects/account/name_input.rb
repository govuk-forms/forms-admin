class Account::NameInput < BaseInput
  attr_accessor :pending_user, :name

  validates :name, presence: true

  def submit
    return false if invalid?

    pending_user.name = name
    pending_user.save!
  end

  def assign_form_values
    self.name = pending_user.name
    self
  end
end
