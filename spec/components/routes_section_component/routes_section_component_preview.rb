class RoutesSectionComponent::RoutesSectionComponentPreview < ViewComponent::Preview
  include FactoryBot::Syntax::Methods

  def with_selection_question_with_one_option_only
    page = build(:page, id: 1, form_id: 1, position: 1, routing_conditions: [])
    draft_question = build(:selection_draft_question, only_one_option: "true")
    render(RoutesSectionComponent::View.new(page:, draft_question:))
  end

  def with_question_that_is_not_selection_with_one_option_only
    page = build(:page, id: 1, form_id: 1, position: 1, routing_conditions: [])
    draft_question = build(:draft_question, answer_type: "email")
    page.define_singleton_method(:has_next_page?) { true }

    render(RoutesSectionComponent::View.new(page:, draft_question:))
  end

  def with_routes
    condition = build(:condition, id: 1, routing_page_id: 1, check_page_id: 1, answer_value: "Option 1", skip_to_end: true)
    page = build(:page, id: 1, form_id: 1, position: 1, routing_conditions: [condition])
    draft_question = build(:selection_draft_question, only_one_option: "true")
    render(RoutesSectionComponent::View.new(page:, draft_question:))
  end
end
