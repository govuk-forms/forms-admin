class StepSummaryCardService
  include ActionView::Helpers::TagHelper

  class << self
    def call(**args)
      new(**args)
    end
  end

  def initialize(step:, steps:, read_only: true, multiple_branches_enabled: false)
    @read_only = read_only
    @step = step
    @steps = steps
    @multiple_branches_enabled = multiple_branches_enabled
  end

  def all_options_for_answer_type
    options = []

    # Prioritize guidance markdown for file uploads
    options.concat(guidance_markdown_options) if @step.respond_to?(:guidance_markdown) && @step.guidance_markdown.present?

    # Page heading for non-file types
    options.concat(page_heading_options) if @step.respond_to?(:page_heading) && @step.page_heading.present? && @step.answer_type != "file"

    # File upload: If a page heading/guidance is present, show the question text in the body of the summary card
    # as we're using the heading in the title rather than the question text.
    options.concat(question_text_options) if @step.answer_type == "file" && @step.page_heading.present?

    # Other answer types
    options.concat(hint_options) if @step.hint_text.present?
    options.concat(generic_options) if @read_only && %w[address date text selection name].exclude?(@step.answer_type)

    options.concat(selection_options) if @step.answer_type == "selection"
    options.concat(text_options) if @step.answer_type == "text"
    options.concat(date_options) if @step.answer_type == "date"
    options.concat(address_options) if @step.answer_type == "address"
    options.concat(name_options) if @step.answer_type == "name"
    options.concat(route_options) if @step.respond_to?(:routing_conditions) && @step.routing_conditions.present?
    options
  end

private

  def page_heading_options
    [{
      key: { text: I18n.t("step_summary_card.page_heading") },
      value: { text: @step.page_heading },
    }]
  end

  def question_text_options
    [{
      key: { text: I18n.t("reports.form_or_questions_list_table.headings.question_text") },
      value: { text: @step.question_text },
    }]
  end

  def markdown_content
    safe_join(['<pre class="app-markdown-editor__markdown-example-block">'.html_safe, @step.guidance_markdown, "</pre>".html_safe])
  end

  def guidance_markdown_options
    [{
      key: { text: I18n.t("step_summary_card.guidance_markdown") },
      value: { text: markdown_content },
    }]
  end

  def hint_options
    [{
      key: { text: I18n.t("step_summary_card.hint_text") },
      value: { text: @step.hint_text },
    }]
  end

  def generic_options
    [].tap do |options|
      options << {
        key: { text: I18n.t("step_summary_card.answer_type") },
        value: { text: I18n.t("helpers.label.page.answer_type_options.names.#{@step.answer_type}") },
      }
    end
  end

  def selection_options
    options = [
      { key: { text: I18n.t("step_summary_card.answer_type") }, value: { text: selection_answer_type } },
      { key: { text: I18n.t("step_summary_card.options_title") }, value: { text: selection_list } },
    ]

    none_of_the_above_question_text = get_none_of_the_above_question_text
    if @step.is_optional? && none_of_the_above_question_text.present?
      question_text = none_of_the_above_question_text
      options << {
        key: { text: I18n.t("step_summary_card.none_of_the_above_question_title") },
        value: { text: question_text },
      }
    end

    options
  end

  def selection_answer_type
    return I18n.t("step_summary_card.selection_type.default") unless @step.answer_settings.only_one_option == "true"

    I18n.t("step_summary_card.selection_type.only_one_option")
  end

  def selection_list
    return @step.show_selection_options unless @step.answer_settings.selection_options.length >= 1

    options = @step.answer_settings.selection_options.map(&:name)
    options << I18n.t("step_summary_card.selection_type.none_of_the_above.en") if @step.is_optional?
    formatted_list = html_unordered_list(options)

    if options.length > 10
      details_summary = I18n.t("page_settings_summary.selection.options_summary", number_of_options: options.length)
      GovukComponent::DetailsComponent.new(summary_text: details_summary)
                                      .with_content(formatted_list)
                                      .call
    else
      caption = content_tag(:p, I18n.t("page_settings_summary.selection.options_count", number_of_options: options.length), class: "govuk-body-s")
      safe_join([caption, formatted_list])
    end
  end

  def get_none_of_the_above_question_text
    none_of_the_above_question = @step.answer_settings.none_of_the_above_question
    return nil if none_of_the_above_question.blank? || none_of_the_above_question.question_text.blank?

    if ActiveRecord::Type::Boolean.new.cast(none_of_the_above_question.is_optional)
      I18n.t("step_summary_card.none_of_the_above_question_optional", question_text: none_of_the_above_question.question_text)
    else
      none_of_the_above_question.question_text
    end
  end

  def text_options
    [{ key: { text: I18n.t("step_summary_card.answer_type") }, value: { text: I18n.t("helpers.label.page.text_settings_options.names.#{@step.answer_settings.input_type}") } }]
  end

  def date_options
    [{ key: { text: I18n.t("step_summary_card.answer_type") }, value: { text: I18n.t("step_summary_card.date_type.#{@step.answer_settings.input_type}") } }]
  end

  def address_options
    [{ key: { text: I18n.t("step_summary_card.answer_type") }, value: { text: I18n.t("helpers.label.page.address_settings_options.names.#{address_input_type_to_string}") } }]
  end

  def name_options
    [{ key: { text: I18n.t("step_summary_card.answer_type") }, value: { text: name_answer_type } }]
  end

  def name_answer_type
    title_needed = if @step.answer_settings.title_needed == "true"
                     I18n.t("step_summary_card.name_type.title_selected")
                   else
                     I18n.t("step_summary_card.name_type.title_not_selected")
                   end

    settings = [I18n.t("helpers.label.page.answer_type_options.names.#{@step.answer_type}"),
                I18n.t("helpers.label.page.name_settings_options.names.#{@step.answer_settings.input_type}")]
    settings << title_needed

    formatted_list = html_list_item(settings)

    ActionController::Base.helpers.sanitize("<ul class='govuk-list'>#{formatted_list}</ul>")
  end

  def address_input_type_to_string
    input_type = @step.answer_settings.input_type
    if input_type.uk_address == "true" && input_type.international_address == "true"
      "uk_and_international_addresses"
    elsif input_type.uk_address == "true"
      "uk_addresses"
    else
      "international_addresses"
    end
  end

  def route_options
    if @multiple_branches_enabled
      [{ key: { text: I18n.t("page_conditions.route2", count: number_of_routes) }, value: { text: route_value2 } }]
    else
      [{ key: { text: I18n.t("page_conditions.route") }, value: { text: route_value.html_safe } }]
    end
  end

  def number_of_routes
    if @step.routing_conditions.length == 1
      1
    else
      answer_value_groups(@step.routing_conditions).length
    end
  end

  def route_value
    if @step.routing_conditions.length == 1
      print_route(@step.routing_conditions.first)
    else
      html_ordered_list(@step.routing_conditions.map { |condition| print_route(condition) })
    end
  end

  def route_value2
    if @step.routing_conditions.first.answer_value.present?
      print_routes(@step.routing_conditions)
    else
      print_unconditional_route(@step.routing_conditions.first)
    end
  end

  def print_unconditional_route(condition)
    if condition.skip_to_end
      I18n.t("page_conditions.unconditional_skip_to_end_of_form").html_safe
    else
      goto_question = @steps.find { |page| page.id == condition.goto_page_id }
      goto_page_question_text = ActionController::Base.helpers.sanitize(goto_question.question_text)
      goto_page_question_number = @steps.find_index(goto_question) + 1

      I18n.t("page_conditions.unconditional_go_to_page", goto_page_question_number:, goto_page_question_text:).html_safe
    end
  end

  def print_routes(conditions)
    answer_value_groups = answer_value_groups(conditions)
    answer_value_groups.map { |group|
      condition_group = group[:conditions]

      if group[:group_type] == :skip_to_end
        caption = content_tag(:p, I18n.t("page_conditions.go_to_the_end"), class: "govuk-body-s")
      elsif group[:group_type] == :exit_page
        caption = content_tag(:p, I18n.t("page_conditions.go_to_exit_page", exit_page_index: group[:exit_page_index], exit_page_heading: group[:exit_page].heading), class: "govuk-body-s")
      else
        goto_question = @steps.find { |page| page.id == condition_group.first.goto_page_id }
        goto_page_question_text = ActionController::Base.helpers.sanitize(goto_question.question_text)
        goto_page_question_number = @steps.find_index(goto_question) + 1

        caption = content_tag(:p, I18n.t("page_conditions.go_to_page", goto_page_question_number:, goto_page_question_text:), class: "govuk-body-s")
      end

      answer_values = condition_group.map { |condition| "‘#{format_answer_value(condition.answer_value)}’" }
      formatted_list = html_unordered_list2(answer_values)
      safe_join([caption, formatted_list])
    }.join.html_safe
  end

  def print_route(condition)
    answer_value = format_answer_value(condition.answer_value)

    if condition.skip_to_end && condition.secondary_skip?
      I18n.t("page_conditions.condition_compact_html_secondary_skip_to_end_of_form")
    elsif condition.skip_to_end
      I18n.t("page_conditions.condition_compact_html_end_of_form", answer_value:).html_safe
    elsif condition.secondary_skip?
      goto_question = @steps.find { |page| page.id == condition.goto_page_id }
      goto_page_question_text = ActionController::Base.helpers.sanitize(goto_question.question_text)
      goto_page_question_number = @steps.find_index(goto_question) + 1

      I18n.t("page_conditions.condition_compact_html_secondary_skip", goto_page_question_number:, goto_page_question_text:).html_safe
    elsif condition.exit_page?
      I18n.t("page_conditions.condition_compact_html_exit_page", answer_value:, exit_page_heading: condition.exit_page_heading).html_safe
    else
      goto_question = @steps.find { |page| page.id == condition.goto_page_id }
      goto_page_question_text = ActionController::Base.helpers.sanitize(goto_question.question_text)
      goto_page_question_number = @steps.find_index(goto_question) + 1

      I18n.t("page_conditions.condition_compact_html", answer_value:, goto_page_question_number:, goto_page_question_text:).html_safe
    end
  end

  def format_answer_value(answer_value)
    answer_value = I18n.t("page_conditions.none_of_the_above") if answer_value == Condition::NONE_OF_THE_ABOVE
    ActionController::Base.helpers.sanitize(answer_value)
  end

  def html_ordered_list(list_items)
    content_tag(:ol, html_list_item(list_items), class: ["govuk-list", "govuk-list--number"])
  end

  def html_unordered_list(list_items)
    content_tag(:ul, html_list_item(list_items), class: ["govuk-list", "govuk-list--bullet"])
  end

  def html_unordered_list2(list_items)
    content_tag(:ul, html_list_item(list_items), class: ["govuk-list", "govuk-list--bullet govuk-!-static-margin-bottom-4"])
  end

  def html_list_item(item)
    item.map { |i| content_tag(:li, i) }.join.html_safe
  end

  def answer_value_groups(conditions)
    answer_order = @step.answer_settings&.selection_options&.map(&:value) || []

    ordered_conditions = conditions.to_a
      .in_order_of(:answer_value, answer_order, filter: false)

    groups = []

    goto_page_groups = ordered_conditions.select { |condition| condition.goto_page_id.present? }.group_by(&:goto_page_id)
    goto_page_groups.each_value do |grouped_conditions|
      groups << {
        group_type: :goto_page,
        conditions: grouped_conditions,
      }
    end

    skip_to_end_conditions = ordered_conditions.select(&:skip_to_end)

    if skip_to_end_conditions.any?
      groups << {
        group_type: :skip_to_end,
        conditions: skip_to_end_conditions,
      }
    end

    exit_page_groups = ordered_conditions.select { |condition| condition.exit_page_id.present? }
      .group_by(&:exit_page_id)
      .values
      .sort_by { |grouped_conditions| grouped_conditions.first.exit_page_id }

    exit_page_groups.each do |grouped_conditions|
      exit_page = @step.exit_pages.detect { it.id == grouped_conditions.first.exit_page_id }

      groups << {
        group_type: :exit_page,
        exit_page_index: exit_page_position_calc(exit_page),
        conditions: grouped_conditions,
        exit_page:,
      }
    end

    groups
  end

  def exit_page_position_calc(exit_page)
    @step.exit_pages.find_index(exit_page) + 1
  end
end
