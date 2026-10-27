# frozen_string_literal: true

module RoutesSectionComponent
  class View < ApplicationComponent
    include Rails.application.routes.url_helpers

    def initialize(page:, draft_question:)
      super()
      @page = page
      @draft_question = draft_question
    end

    def render?
      message_key.present?
    end

    def message_key
      @message_key ||= if @page.routing_conditions.any?
                         "has_routes_html"
                       elsif selection_question_with_one_option_only?
                         "conditional_routes_html"
                       elsif @page.has_next_page?
                         "skip_questions_html"
                       end
    end

  private

    def selection_question_with_one_option_only?
      @draft_question.answer_type == "selection" &&
        @draft_question.answer_settings[:only_one_option] == "true" &&
        @draft_question.answer_settings[:selection_options].length <= 10
    end
  end
end
