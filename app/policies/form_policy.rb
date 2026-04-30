class FormPolicy
  attr_reader :user, :form

  def initialize(user, form)
    @user = user
    @form = form
  end

  def can_view_form?
    return true if user.super_admin?

    user.groups.include?(form.group) || user.is_organisations_admin?(form.group&.organisation)
  end

  alias_method :can_edit_form?, :can_view_form?
  alias_method :copy?, :can_view_form?
  alias_method :delete?, :can_edit_form?
  alias_method :destroy?, :delete?

  def can_add_page_routing_conditions?
    form_has_two_or_more_pages = form.pages.length >= 2
    form_has_qualifying_pages = form.qualifying_route_pages.any?

    form_has_two_or_more_pages && form_has_qualifying_pages
  end

  def can_make_form_live?
    return can_view_form? if form.group&.active? && can_administer_group?

    false
  end

  def can_make_language_live?
    return can_view_form? if form.group&.active? && can_administer_group?

    false
  end

  def can_administer_group?
    user.super_admin? || user.is_organisations_admin?(form.group&.organisation) || user.is_group_admin?(form.group)
  end
end
