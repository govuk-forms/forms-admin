class Organisation < ApplicationRecord
  has_paper_trail

  has_many :groups
  has_many :users

  has_many :org_domains, dependent: :destroy
  has_many :mou_signatures

  scope :not_closed, -> { where(closed: false) }
  scope :with_users, -> { joins(:users).distinct.order(:name) }

  def name_with_abbreviation
    if abbreviation.present? && abbreviation != name
      "#{name} (#{abbreviation})"
    else
      name
    end
  end

  def admin_users
    users.organisation_admin
  end

  alias_method :organisation_admin_users, :admin_users

  def as_json(options = {})
    options[:only] ||= %i[id name]
    options[:methods] ||= %i[organisation_admin_users]
    super(options)
  end

  def self.for_email(email)
    domain = email.split('@').last.downcase

    not_closed
      .joins(:org_domains)
      .where(org_domains: { domain: domain })
      .distinct
  end
end
