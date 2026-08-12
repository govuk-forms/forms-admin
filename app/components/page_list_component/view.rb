module PageListComponent
  class View < ApplicationComponent
    delegate :question_text_with_optional_suffix, to: :helpers

    def initialize(form:, pages: [])
      super()
      @form = form
      @pages = pages
    end

    def show_up_button(index)
      index != 0
    end

    def show_down_button(index)
      index != @pages.length - 1
    end

    def page_row_id(record)
      "page_#{record.id}"
    end

    def condition_description(condition)
      if condition.secondary_skip?
        I18n.t("page_conditions.secondary_skip_description", check_page_question_text: skip_condition_route_page_text(condition), goto_page_question_text: goto_page_text_for_condition(condition))
      else
        I18n.t("page_conditions.condition_description", check_page_question_text: condition_check_page_text(condition), goto_page_question_text: goto_page_text_for_condition(condition), answer_value: answer_value_text_for_condition(condition))
      end
    end

    def unconditional_description(condition)
      if condition.goto_page_id.present?
        goto_page = @pages.find { |page| page.id == condition.goto_page_id }
        I18n.t("page_conditions.unconditional_goto_page_text", goto_page_question_number: goto_page.position, goto_page_question_text: goto_page.question_text)
      elsif condition.skip_to_end
        I18n.t("page_conditions.unconditional_skip_to_end_text")
      end
    end

    def condition_group_description(group)
      case group[:group_type]
      when :skip_to_end
        I18n.t("page_conditions.condition_group_description_end_of_form")
      when :exit_page
        I18n.t("page_conditions.condition_group_description_exit_page", exit_page_heading: group[:conditions].first.exit_page.heading, exit_page_index: group[:exit_page_index])
      when :goto_page
        goto_page = @pages.find { |page| page.id == group[:conditions].first.goto_page_id }
        I18n.t("page_conditions.condition_group_description", goto_page_question_text: goto_page.question_text, goto_page_question_number: goto_page.position)
      end
    end

    def condition_check_page_text(condition)
      check_page = @pages.find { |page| page.id == condition.check_page_id }
      I18n.t("page_conditions.condition_check_page_text", check_page_question_text: check_page.question_text)
    end

    def answer_value_text_for_condition(condition)
      if condition.answer_value.present?
        answer_value = condition.answer_value == Condition::NONE_OF_THE_ABOVE ? I18n.t("page_conditions.none_of_the_above") : condition.answer_value
        I18n.t("page_conditions.condition_answer_value_text", answer_value:)
      else
        I18n.t("page_conditions.condition_answer_value_text_with_errors")
      end
    end

    def answer_value_text_for_condition2(condition)
      if condition.answer_value.present?
        answer_value = condition.answer_value == Condition::NONE_OF_THE_ABOVE ? I18n.t("page_conditions.none_of_the_above") : condition.answer_value
        I18n.t("page_conditions.condition_answer_value_text2", answer_value:)
      else
        I18n.t("page_conditions.condition_answer_value_text_with_errors")
      end
    end

    def goto_page_text_for_condition(condition)
      if condition.goto_page_id.present?
        goto_page = @pages.find { |page| page.id == condition.goto_page_id }
        I18n.t("page_conditions.condition_goto_page_text", goto_page_question_number: goto_page.position, goto_page_question_text: goto_page.question_text)
      elsif condition.skip_to_end
        I18n.t("page_conditions.condition_goto_page_end_of_form")
      elsif condition.exit_page?
        I18n.t("page_conditions.condition_goto_exit_page", exit_page_heading: condition.exit_page_heading)
      else
        I18n.t("page_conditions.condition_goto_page_text_with_errors")
      end
    end

    def page_position(page)
      page.position
    end

    def condition_page(condition)
      condition.attributes["check_page"] ||= @pages.find { |page| page.id == condition.check_page_id }
    end

    def condition_page_position(condition)
      check_page = condition_page(condition)
      page_position(check_page)
    end

    def skip_condition_route_page_text(condition)
      routing_page = @pages.find { |page| page.id == condition.routing_page_id }
      I18n.t("page_conditions.skip_condition_route_page_text", route_page_question_text: routing_page.question_text, route_page_question_number: routing_page.position)
    end

    def answer_value_groups(page)
      answer_order = page.answer_settings&.selection_options&.map(&:value) || []

      conditions = page.routing_conditions.to_a
        .in_order_of(:answer_value, answer_order, filter: false)

      groups = []

      goto_page_groups = conditions.select { |condition| condition.goto_page_id.present? }.group_by(&:goto_page_id)
      goto_page_groups.each_value do |grouped_conditions|
        groups << {
          group_type: :goto_page,
          conditions: grouped_conditions,
        }
      end

      skip_to_end_conditions = conditions.select(&:skip_to_end)

      if skip_to_end_conditions.any?
        groups << {
          group_type: :skip_to_end,
          conditions: skip_to_end_conditions,
        }
      end

      exit_page_groups = conditions.select { |condition| condition.exit_page.present? }
        .group_by { |condition| condition.exit_page.id }
        .values
        .sort_by { |grouped_conditions| grouped_conditions.first.exit_page&.created_at }

      exit_page_positions = ExitPage.positions_for_page(page)

      exit_page_groups.each do |grouped_conditions|
        groups << {
          group_type: :exit_page,
          exit_page_index: exit_page_positions[grouped_conditions.first.exit_page.id],
          conditions: grouped_conditions,
        }
      end

      groups
    end
  end
end
