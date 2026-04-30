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

    def branch_condition_description(condition)
      if condition.answer_value.present?
        I18n.t("page_conditions.branch_condition_description", goto_page_question_text: goto_page_text_for_condition(condition), answer_value: answer_value_text_for_condition(condition))
      else
        I18n.t("page_conditions.unconditional_description", goto_page_question_text: goto_page_text_for_condition(condition))
      end
    end

    def condition_check_page_text(condition)
      check_page = @pages.find { |page| page.id == condition.check_page_id }
      I18n.t("page_conditions.condition_check_page_text", check_page_question_text: check_page.question_text)
    end

    def answer_value_text_for_condition(condition)
      if condition.answer_value.present?
        answer_value = condition.answer_value == :none_of_the_above.to_s ? I18n.t("page_conditions.none_of_the_above") : condition.answer_value
        I18n.t("page_conditions.condition_answer_value_text", answer_value:)
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
  end
end
