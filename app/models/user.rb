class User < ApplicationRecord
  # TODO: Drop this column in a future migration
  self.ignored_columns += [:remotely_signed_out]

  class UserAuthenticationException < StandardError; end

  EMAIL_DOMAIN_DENYLIST = [
    "dwp.gov.uk",
    "engineering.dwp.gov.uk",
    "engineering.digital.dwp.gov.uk",
    "hse.gov.uk",
  ].freeze

  belongs_to :organisation, optional: true

  has_many :memberships, dependent: :destroy
  has_many :groups, through: :memberships

  has_many :mou_signatures
  has_many :draft_questions

  serialize :permissions, coder: YAML, type: Array

  enum :research_contact_status, {
    consented: "consented",
    declined: "declined",
    to_be_asked: "to_be_asked",
  }, prefix: "research_contact"

  has_paper_trail only: %i[role organisation_id has_access]

  enum :role, {
    super_admin: "super_admin",
    organisation_admin: "organisation_admin",
    standard: "standard",
  }

  scope :for_users_list, lambda {
    includes(:organisation)
      .order(Arel.sql("organisation.name ASC NULLS FIRST"))
      .order({ has_access: :desc })
      .in_order_of(:role, roles.keys)
      .order({ name: :asc })
  }

  scope :by_name, lambda { |name|
    if name.present?
      where("lower(users.name) LIKE ?", "%#{sanitize_sql_like(name.downcase)}%")
    end
  }

  scope :by_email, lambda { |email|
    if email.present?
      where("lower(email) LIKE ?", "%#{sanitize_sql_like(email.downcase)}%")
    end
  }

  scope :by_organisation_id, lambda { |organisation_id|
    if organisation_id.present?
      joins(:organisation).where(organisation: { id: organisation_id })
    end
  }

  scope :by_role, lambda { |role|
    if role.present?
      where(role:)
    end
  }

  scope :by_has_access, lambda { |has_access|
    if has_access.present?
      where(has_access:)
    end
  }

  validates :name, presence: true, if: :requires_name?
  validates :role, presence: true
  validates :organisation_id, presence: true, if: :requires_organisation?
  validates :has_access, inclusion: [true, false]
  validates :role, exclusion: %w[organisation_admin], unless: :current_org_has_mou?
  validates :email, uniqueness: { case_sensitive: false }

  before_create do
    self.has_access = false if organisation_restricted_access?
  end

  def self.find_for_auth(attributes)
    user = where(provider: attributes[:provider], uid: attributes[:uid]).first ||
      where("lower(email) = ?", attributes[:email].downcase).first

    if user
      user.assign_attributes(attributes)

      if user.has_changes_to_save?
        Rails.logger.info("User attributes updated upon authorisation", {
          user_changes: user.changes_to_save,
        })
      end

      user.save!
      user
    else
      # Create a new user.
      create!(attributes)
    end
  end

  def given_organisation?
    organisation_id.present? && organisation_id_previously_changed?(from: nil)
  end

  def has_signed_current_organisation_mou?
    mou_signatures.where(organisation: organisation || nil).exists?
  end

  def organisation_restricted_access?
    email_domain = email.present? ? email.split("@").last : nil

    EMAIL_DOMAIN_DENYLIST.include?(email_domain)
  end

  def current_organisation_mou_signature
    mou_signatures.find_by(organisation:)
  end

  def can_administer_org?(org)
    is_organisations_admin?(org) || super_admin?
  end

  def is_organisations_admin?(org)
    organisation_admin? && organisation == org
  end

  def is_group_admin?(group)
    memberships.find_by(group:)&.group_admin?
  end

  def current_org_has_mou?
    organisation&.mou_signatures.present?
  end

  def collect_analytics?
    Settings.analytics_enabled && !super_admin?
  end

  def signed_in!
    update!(last_signed_in_at: Time.zone.now)
  end

  def as_json(options = {})
    options[:only] ||= %i[name email]
    super(options)
  end

private

  def requires_name?
    name_was.present?
  end

  def requires_organisation?
    organisation.blank? && (organisation_id_was.present? || role_changed?(to: :organisation_admin))
  end
end
