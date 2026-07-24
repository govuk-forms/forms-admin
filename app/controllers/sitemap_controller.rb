class SitemapController < WebController
  def index
    active_groups = current_user.groups.active.order(:name)
    trial_groups = current_user.groups.trial.order(:name)

    render locals: { active_groups:,
                     trial_groups:,
                     should_show_users_link: should_show_users?,
                     should_show_organisations_link: should_show_organisations_link?,
                     should_show_reports_link: should_show_reports_link? }
  end

  def should_show_users?
    Pundit.policy(current_user, :user).can_manage_user?
  end

  def should_show_organisations_link?
    Pundit.policy(current_user, :organisation).can_view_organisations?
  end

  def should_show_reports_link?
    Pundit.policy(current_user, :report).can_view_reports?
  end
end
