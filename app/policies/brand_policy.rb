class BrandPolicy < ApplicationPolicy
  def can_view_brands?
    user.super_admin?
  end
end
