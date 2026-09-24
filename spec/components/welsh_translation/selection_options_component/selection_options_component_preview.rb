class WelshTranslation::SelectionOptionsComponent::SelectionOptionsComponentPreview < ViewComponent::Preview
  include FactoryBot::Syntax::Methods

  def short_list
    page = build(:page, :selection_with_radios, id: 1, position: 1)
    render_component(page)
  end

  def long_list_without_translations
    page = build(:page, :selection_with_autocomplete, id: 1, position: 1)
    render_component(page)
  end

  def long_list_with_some_translations
    page = build(:page, :selection_with_autocomplete, id: 1, position: 1)
    input = Forms::WelshPageTranslationInput.new(page:).assign_page_values
    input.selection_options_cy.first(3).each_with_index do |option, i|
      option.name_cy = "Welsh option #{i + 1}"
    end
    render(WelshTranslation::SelectionOptionsComponent::View.new(
             page_form: page_form_for(input),
             table_presenter: Forms::TranslationTablePresenter.new,
           ))
  end

  def long_list_with_translations_and_errors
    page = build(:page, :selection_with_autocomplete, id: 1, position: 1)
    input = Forms::WelshPageTranslationInput.new(page:).assign_page_values
    input.selection_options_cy.first(5).each_with_index do |option, i|
      option.name_cy = "Welsh option #{i + 1}"
    end
    input.selection_options_cy[5].name_cy = "a" * 260
    input.selection_options_cy[6].name_cy = "a" * 260
    input.validate
    render(WelshTranslation::SelectionOptionsComponent::View.new(
             page_form: page_form_for(input),
             table_presenter: Forms::TranslationTablePresenter.new,
           ))
  end

  def short_list_with_validation_error
    page = build(:page, :selection_with_radios, id: 1, position: 1)
    input = Forms::WelshPageTranslationInput.new(page:).assign_page_values
    input.selection_options_cy.first.name_cy = "a" * 260
    input.validate
    render(WelshTranslation::SelectionOptionsComponent::View.new(
             page_form: page_form_for(input),
             table_presenter: Forms::TranslationTablePresenter.new,
           ))
  end

private

  def render_component(page)
    input = Forms::WelshPageTranslationInput.new(page:).assign_page_values
    render(WelshTranslation::SelectionOptionsComponent::View.new(
             page_form: page_form_for(input),
             table_presenter: Forms::TranslationTablePresenter.new,
           ))
  end

  def page_form_for(input)
    GOVUKDesignSystemFormBuilder::FormBuilder.new(
      :forms_welsh_page_translation_input,
      input,
      ActionView::Base.new(ActionView::LookupContext.new(nil), {}, nil),
      {},
    )
  end
end
