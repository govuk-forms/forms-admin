class Group < ApplicationRecord
  belongs_to :organisation

  belongs_to :creator, class_name: "User", optional: true

  belongs_to :upgrade_requester, class_name: "User", optional: true

  default_scope { order("LOWER(name)", :created_at) }

  has_many :memberships, dependent: :destroy do
    def ordered
      joins(:user).order("users.name")
    end
  end
  has_many :users, through: :memberships do
    def group_admins
      where(memberships: { role: "group_admin" })
    end
  end

  has_many :group_forms, dependent: :restrict_with_exception
  has_many :forms, through: :group_forms, dependent: :restrict_with_exception

  scope :for_user, ->(user) { joins(:memberships).where(memberships: { user_id: user.id }) }

  scope :for_organisation, ->(organisation) { where(organisation:) }

  validates :name, presence: true, uniqueness: { scope: :organisation_id }
  before_create :set_external_id

  enum :status, { trial: "trial", active: "active", upgrade_requested: "upgrade_requested" }, validate: true

  # Feature flag columns that super admins can toggle per group. Derived from the
  # features in settings.yml marked `enabled_by_group: true` that also have a matching
  # `*_enabled` column (features without a column, e.g. exit_pages, are skipped).
  def self.feature_flag_attributes
    return [] if Settings.features.blank?

    Settings.features.filter_map do |name, config|
      column = "#{name}_enabled"
      column if config.respond_to?(:enabled_by_group) && config.enabled_by_group && has_attribute?(column)
    end
  end

  def to_param
    external_id
  end

  def as_json(options = {})
    options[:only] ||= %i[name external_id]
    options[:methods] ||= %i[group_admin_users organisation]
    super(options)
  end

private

  def set_external_id
    self.external_id = ExternalIdProvider.generate_unique_id_for(Group)
  end

  def group_admin_users
    users.group_admins
  end
end
