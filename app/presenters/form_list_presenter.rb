class FormListPresenter
  include Rails.application.routes.url_helpers
  include ActionView::Helpers::UrlHelper
  include GovukLinkHelper
  include GovukVisuallyHiddenHelper

  attr_accessor :forms, :group

  class << self
    def call(**args)
      new(**args)
    end
  end

  def initialize(forms:, group:, can_admin: false)
    @forms = forms
    @group = group
    @can_admin = can_admin
    @list_of_creator_id = forms.map(&:creator_id).uniq
    @list_of_creators = User.where(id: @list_of_creator_id)
                             .select(:id, :name)
                             .map { |user| { id: user.id, name: user.name } }
  end

  def data
    {
      caption:,
      head:,
      rows:,
    }
  end

private

  def caption
    I18n.t("groups.form_table_caption", group_name: group.name)
  end

  def head
    head = [
      I18n.t("home.form_name_heading"),
      { text: I18n.t("home.created_by") },
      { text: I18n.t("home.form_status_heading"), numeric: true },
    ]

    head << { text: I18n.t("home.actions"), numeric: true } if @can_admin

    head.compact
  end

  def rows
    rows = forms.sort_by { |form| [form.name.downcase, form.created_at] }.map do |form|
      row = [{ text: form_name_link(form) + welsh_status(form) },
             { text: find_creator_name(form) },
             { text: form_status_tags(form), numeric: true }]

      row << { text: change_group_link(form), numeric: true } if @can_admin

      row
    end

    rows.compact
  end

  def form_name_link(form)
    govuk_link_to(form.name, FormService.new(form).path_for_state)
  end

  def change_group_link(form)
    govuk_link_to(
      I18n.t("home.move_form"),
      edit_group_form_path(group, id: form.id),
      visually_hidden_suffix: I18n.t("home.for", form_name: form.name),
    )
  end

  def welsh_status(form)
    if form.live_welsh_form_document.present?
      "<p class=\"govuk-!-margin-bottom-1 govuk-!-margin-top-2 govuk-hint\">With Welsh version</p>".html_safe
    elsif form.draft_welsh_form_document.present?
      "<p class=\"govuk-!-margin-bottom-1 govuk-!-margin-top-2 govuk-hint\">With Welsh draft</p>".html_safe
    elsif form.archived_welsh_form_document.present?
      "<p class=\"govuk-!-margin-bottom-1 govuk-!-margin-top-2 govuk-hint\">With archived Welsh version</p>".html_safe
    end
  end

  def form_status_tags(form)
    # Create an instance of controller. We are using ApplicationController here.
    view_context = ApplicationController.new.view_context

    status_mapping = {
      draft: -> { form.has_draft_version },
      live: -> { form.is_live? },
      archived: -> { form.is_archived? },
    }

    html_content = status_mapping.map { |status, condition|
      FormStatusTagComponent::View.new(status:).render_in(view_context) if condition.call
    }.compact.join

    html = "<div class='app-form-states'>#{html_content}</div>"

    html.html_safe
  end

  def find_creator_name(form)
    @list_of_creators.find { |creator| creator[:id] == form.creator_id }&.fetch(:name, "")
  end
end
