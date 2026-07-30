class Forms::ContactDetailsInput < BaseInput
  attr_accessor :form, :email, :phone, :link_text, :link_href, :contact_details_supplied

  validates :email, presence: true, email_address: true, if: -> { supplied :supply_email }
  validates :email, allowed_email_domain: true, if: -> { supplied :supply_email }
  validates :phone, presence: true, length: { maximum: 500 }, if: -> { supplied :supply_phone }
  validates :link_href, presence: true, url: true, length: { maximum: 500 }, if: -> { supplied :supply_link }
  validates :link_text, presence: true, length: { maximum: 120 }, if: -> { supplied :supply_link }

  def must_be_supply_contact_details
    errors.add(:contact_details_supplied, :must_be_supply_contact_details) if contact_details_supplied.reject(&:blank?).empty?
  end

  def initialize(attrs = {})
    attrs.deep_symbolize_keys!

    super(attrs)

    # Update the values for the checkboxes, so they are shown ticked in error
    # state
    @contact_details_supplied = []
    @contact_details_supplied = attrs[:contact_details_supplied].compact.map(&:to_sym) if attrs.key?(:contact_details_supplied)
  end

  def submit
    form.support_email = nil
    form.support_phone = nil
    form.support_url = nil
    form.support_url_text = nil

    return false if invalid?

    form.support_email = email if supplied(:supply_email)
    form.support_phone = phone if supplied(:supply_phone)
    form.support_url = link_href if supplied(:supply_link)
    form.support_url_text = link_text if supplied(:supply_link)

    form.save_draft!
  end

  def assign_form_values
    self.contact_details_supplied |= [:supply_email] if form.support_email.present?
    self.contact_details_supplied |= [:supply_phone] if form.support_phone.present?
    self.contact_details_supplied |= [:supply_link] if form.support_url.present?

    self.email = form.support_email
    self.phone = form.support_phone
    self.link_href = form.support_url
    self.link_text = form.support_url_text

    self
  end

  def check_email?
    email.present? || supplied(:supply_email)
  end

  def check_phone?
    phone.present? || supplied(:supply_phone)
  end

  def check_link?
    link_href.present? || supplied(:supply_link)
  end

private

  def supplied(field)
    contact_details_supplied.map(&:to_sym).include? field
  end
end
