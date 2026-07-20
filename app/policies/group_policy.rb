class GroupPolicy < ApplicationPolicy
  def new?
    true
  end
  alias_method :create?, :new?

  def show?
    organisation_admin_or_super_admin? || user.groups.include?(record)
  end

  def edit?
    organisation_admin_or_super_admin? || group_admin?
  end

  alias_method :update?, :edit?
  alias_method :add_editor?, :edit?

  def move?
    user.super_admin?
  end

  def manage_feature_flags?
    user.super_admin?
  end

  def delete?
    organisation_admin_or_super_admin?
  end

  alias_method :destroy?, :delete?

  def upgrade?
    organisation_admin_or_super_admin? && record.organisation.mou_signatures.present?
  end

  def add_group_admin?
    organisation_admin_or_super_admin?
  end

  def request_upgrade?
    group_admin? && !record.active? && record.organisation.admin_users.present?
  end

  def review_upgrade?
    organisation_admin_or_super_admin? && record.upgrade_requested?
  end

private

  def organisation_admin_or_super_admin?
    user.super_admin? || user.is_organisations_admin?(record.organisation)
  end

  def group_admin?
    record.memberships.find_by(user:)&.group_admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.super_admin?
        scope.all
      elsif user.organisation_admin?
        scope.for_organisation(user.organisation)
      else
        scope.for_user(user)
      end
    end
  end
end
