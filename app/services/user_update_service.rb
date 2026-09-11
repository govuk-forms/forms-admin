class UserUpdateService
  def initialize(user, params)
    @user = user
    @params = params
  end

  def update_user
    updated = @user.update(@params)
    on_user_update if updated
    updated
  end

private

  def on_user_update
    add_organisation_to_user_mou if @user.given_organisation?
    update_user_memberships
  end

  def add_organisation_to_user_mou
    MouSignature.add_mou_signature_organisation(@user)
  end

  def update_user_memberships
    memberships = Membership.destroy_invalid_organisation_memberships(@user)

    Rails.logger.info(
      "Deleted memberships for groups in previous organiation",
      {
        memberships_user_id: @user.id,
        memberships: memberships.map { { group_external_id: it.group.external_id, role: it.role } },
      },
    )

    memberships
  end
end
