class Organisation < ApplicationRecord
  has_paper_trail

  has_many :groups
  has_many :group_forms, through: :groups
  has_many :users

  has_many :mou_signatures
  has_many :organisation_domains, dependent: :destroy

  has_many :organisation_brands, dependent: :destroy
  has_many :brands, -> { order(:name) }, through: :organisation_brands

  scope :not_closed, -> { where(closed: false) }
  scope :with_users, -> { joins(:users).distinct.order(:name) }

  scope :by_name, lambda { |name|
    if name.present?
      where("lower(name) LIKE :search OR lower(abbreviation) LIKE :search",
            search: "%#{sanitize_sql_like(name.downcase)}%")
    end
  }

  scope :by_agreement_type, lambda { |agreement_type|
    case agreement_type
    when "crown"
      where(id: MouSignature.crown.select(:organisation_id))
    when "non_crown"
      where(id: MouSignature.non_crown.select(:organisation_id))
    when "signed"
      where(id: MouSignature.select(:organisation_id))
    when "none"
      where.missing(:mou_signatures)
    end
  }

  scope :order_by_user_count, lambda {
    order(Arel.sql("(SELECT COUNT(*) FROM users WHERE users.organisation_id = organisations.id) DESC"))
      .order(:name)
  }

  scope :order_by_live_form_count, lambda {
    order(Arel.sql("(SELECT COUNT(*) FROM groups_form_ids INNER JOIN groups ON groups.id = groups_form_ids.group_id INNER JOIN forms ON forms.id = groups_form_ids.form_id WHERE groups.organisation_id = organisations.id AND forms.state IN ('live', 'live_with_draft')) DESC"))
      .order(:name)
  }

  scope :order_by_draft_form_count, lambda {
    order(Arel.sql("(SELECT COUNT(*) FROM groups_form_ids INNER JOIN groups ON groups.id = groups_form_ids.group_id INNER JOIN forms ON forms.id = groups_form_ids.form_id WHERE groups.organisation_id = organisations.id AND forms.state = 'draft') DESC"))
      .order(:name)
  }

  scope :order_by_first_agreement_date, lambda {
    order(Arel.sql("(SELECT MIN(created_at) FROM mou_signatures WHERE mou_signatures.organisation_id = organisations.id) DESC NULLS LAST"))
      .order(:name)
  }

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
end
