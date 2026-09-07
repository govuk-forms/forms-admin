module PagesHelper
  def selection_options_new_path_for_draft_question(draft_question)
    if has_more_than_30_options?(draft_question)
      selection_bulk_options_new_path(form_id: draft_question.form_id)
    else
      selection_options_new_path(form_id: draft_question.form_id)
    end
  end

  def selection_options_edit_path_for_draft_question(draft_question)
    if has_more_than_30_options?(draft_question)
      selection_bulk_options_edit_path(form_id: draft_question.form_id, page_id: draft_question.page_id)
    else
      selection_options_edit_path(form_id: draft_question.form_id, page_id: draft_question.page_id)
    end
  end

  def has_more_than_30_options?(draft_question)
    options = draft_question_selection_options(draft_question)
    options.present? && options.length > 30
  end

  def draft_question_selection_options(draft_question)
    draft_question.answer_settings[:selection_options]
  end

  # option_indexes is either :number or :answer_value
  def selection_options_in_routes_banner(draft_question, selection_options, include_none_of_the_above, option_indexes: :number)
    return unless draft_question.form&.group&.multiple_branches_enabled?

    answer_values_from_options = selection_options.pluck(:value) + [Condition::NONE_OF_THE_ABOVE]
    options_in_routes = draft_question.form.conditions.where(routing_page_id: draft_question.page_id, answer_value: answer_values_from_options).select(:answer_value)

    return if options_in_routes.empty?

    edit_routes_link = govuk_link_to("View your question routes", routes_path(draft_question.form_id))

    if options_in_routes.count == 1 && options_in_routes.first.answer_value == Condition::NONE_OF_THE_ABOVE
      return { heading: "There is a route from ‘None of the above’", text: "If you remove ‘None of the above’, the route will be deleted. #{edit_routes_link}" }
    end

    if options_in_routes.count == 1 && option_indexes == :number
      option_index = selection_options.index { |option| option[:value] == options_in_routes.first.answer_value } + 1
      return { heading: "There is a route from option #{option_index}", text: "If you remove or change option #{option_index}, the route will be deleted. #{edit_routes_link}" }
    end

    if options_in_routes.count == 1 && option_indexes == :answer_value
      option_index = options_in_routes.first.answer_value
      return { heading: "There is a route from ‘#{option_index}’", text: "If you remove or change this option, the route will be deleted. #{edit_routes_link}" }
    end

    total_selection_options_count = selection_options.length + (include_none_of_the_above ? 1 : 0)
    if options_in_routes.count == total_selection_options_count
      return { heading: "There are routes from these options", text: "If you remove or change an option with a route, the route will be deleted. #{edit_routes_link}" }
    end

    { heading: "There are routes from some of these options", text: "If you remove or change an option with a route, the route will be deleted. #{edit_routes_link}" }
  end

  def routes_and_exit_pages(page, count_goto_conditions: false)
    exit_pages = page.exit_pages
    routes = page.routing_conditions
    routes += page.goto_conditions if count_goto_conditions

    if routes.any? && exit_pages.any?
      I18n.t(
        "helpers.pages.routes_and_exit_pages",
        routes: I18n.t("helpers.pages.routes", count: routes.size),
        exit_pages: I18n.t("helpers.pages.exit_pages", count: exit_pages.size),
      )
    elsif routes.any?
      I18n.t("helpers.pages.routes", count: routes.size)
    elsif exit_pages.any?
      I18n.t("helpers.pages.exit_pages", count: exit_pages.size)
    else
      ""
    end
  end
end
