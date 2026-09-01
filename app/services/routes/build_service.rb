##
# Takes a form (with pages and conditions) and builds an array of RouteInput objects
# based on the pages and conditions.
class Routes::BuildService
  END_OF_FORM_OPTION = [I18n.t("page_conditions.end_of_form"), GotoValue::EndOfFormValue.new].freeze
  NONE_OF_THE_ABOVE_OPTION = DataStruct.new(value: Condition::NONE_OF_THE_ABOVE, name: I18n.t("page_conditions.none_of_the_above"))

  attr_reader :form

  def initialize(form:)
    @form = form
  end

  def build_routes
    conditions_by_key = form.conditions.index_by do |c|
      [c.routing_page_id, c.answer_value.presence]
    end

    form.pages.flat_map do |page|
      routes_type = Forms::RoutesInput.routes_type(page)
      case routes_type
      when :selection_options_routes
        build_routes_for_selection_page(page, conditions_by_key)
      when :generic_route
        build_route_for_generic_page(page, conditions_by_key)
      else
        raise "Unexpected routes type :#{routes_type}"
      end
    end
  end

  def options_for_goto_page(page, selected = nil)
    next_page = form.next_page_after(page)

    # If there's no next page then it's the last page of the form.
    # We only need options for this page if there's an error that needs correcting.
    if next_page.nil?
      selected_page = if selected.is_a?(GotoValue::Page)
                        matching_page = form.pages.find { |p| selected.page_id == p.id }
                        option_for_select(matching_page) if matching_page
                      end

      return (exit_pages(page) + [
        selected_page,
        [END_OF_FORM_OPTION.first, GotoValue::DefaultValue.new],
      ]).compact
    end

    # Don't include the current page or pages before in the options,
    # unless the goto page for the existing condition is before the current page,
    # in which case do include that one. Also, change the option for the next page
    # to a different default option.
    next_page_id = next_page.id
    drop = true

    options = all_goto_options.filter_map do |option|
      _, value = option

      if drop
        if value == GotoValue::Page.new(next_page_id)
          drop = false
          ["#{page.position.next}. #{next_page.question_text}", GotoValue::DefaultValue.new]
        elsif selected && value == selected
          option
        end
        # return nil
      else
        option
      end
    end

    exit_pages(page) + options
  end

  def exit_pages(page)
    exit_pages_positions = ExitPage.positions_for_page(page)

    page.exit_pages.in_order_of(:id, exit_pages_positions.keys, filter: false).map do |exit_page|
      ["Exit page #{exit_pages_positions[exit_page.id]}: #{exit_page.heading}", GotoValue::ExitPage.new(exit_page.id)]
    end
  end

private

  def build_routes_for_selection_page(page, conditions_by_key)
    options = page.answer_settings&.selection_options&.dup || []

    options << NONE_OF_THE_ABOVE_OPTION if page.is_optional

    options.map do |option|
      answer_value = option["value"]
      key = [page.id, answer_value]
      condition = conditions_by_key[key]

      Forms::RouteInput.new(
        id: condition&.id,
        page_id: page.id,
        page:,
        answer_value:,
        goto: goto_value_for(condition),
        goto_page: condition&.goto_page,
        goto_options: options_for_goto_page(page, condition&.goto_page_id),
      )
    end
  end

  def build_route_for_generic_page(page, conditions_by_key)
    key = [page.id, nil]
    condition = conditions_by_key[key]

    selected = GotoValue::Page.new(condition&.goto_page_id) if condition&.goto_page_id.present?
    [
      Forms::RouteInput.new(
        id: condition&.id,
        page_id: page.id,
        page:,
        goto: goto_value_for(condition),
        goto_page: condition&.goto_page,
        goto_options: options_for_goto_page(page, selected),
      ),
    ]
  end

  def option_for_select(page)
    ["#{page.position}. #{page.question_text}", GotoValue::Page.new(page.id)]
  end

  def all_goto_options
    @all_goto_options ||= begin
      page_opts = form.pages.map { |p| option_for_select(p) }
      page_opts + [END_OF_FORM_OPTION]
    end
  end

  def goto_value_for(condition)
    return GotoValue::DefaultValue.new unless condition

    if condition.skip_to_end?
      GotoValue::EndOfFormValue.new
    elsif condition.exit_page_id.present?
      GotoValue::ExitPage.new(condition.exit_page_id)
    else
      GotoValue::Page.new(condition.goto_page_id)
    end
  end
end
