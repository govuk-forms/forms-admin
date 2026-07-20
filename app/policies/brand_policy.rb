class BrandPolicy < ApplicationPolicy
  def can_view_brands?
    user.super_admin?
  end

  def can_edit_brands?
    user.super_admin?
  end
end
