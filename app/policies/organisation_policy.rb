class OrganisationPolicy < ApplicationPolicy
  def can_view_organisations?
    user.super_admin?
  end

  def can_manage_organisation_brands?
    user.super_admin?
  end
end
