# frozen_string_literal: true

module WelshTranslation
  module SelectionOptionsComponent
    class View < ApplicationComponent
      def initialize(page_form:, table_presenter:)
        super()
        @page_form = page_form
        @table_presenter = table_presenter
      end

      def render?
        @page_form.object.page_has_selection_options?
      end

      def long_list_without_translations?
        long_list? && !has_translated_selection_options? && !has_errors?
      end

      def collapsed_options
        return [] if all_options_error?

        @collapsed_options ||= @page_form.object.selection_options_cy.filter { |option| option.name_cy.present? && option.errors.none? }
      end

      def hide_option?(selection_options_form)
        long_list? && selection_options_form.object.errors.none? && !all_options_error?
      end

      def question_number
        @page_form.object.page.position
      end

      def long_list?
        @page_form.object.page.answer_settings.selection_options.size > 30
      end

    private

      def has_translated_selection_options?
        @page_form.object.selection_options_cy.filter { |option| option.name_cy.present? }.any?
      end

      def has_errors?
        @page_form.object.selection_options_cy.filter { |option| option.errors.any? }.any? || all_options_error?
      end

      def all_options_error?
        @page_form.object.errors[:selection_options_cy].any?
      end
    end
  end
end
