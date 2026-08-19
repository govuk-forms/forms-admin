class Forms::RoutesInput < BaseInput
  include ActionView::Helpers::FormTagHelper

  attr_accessor :form, :routes

  validate :routes_are_valid

  def self.too_many_selection_options?(page)
    page.answer_settings["selection_options"].length > 10
  end

  def self.route_with_selection_options?(page)
    page.answer_type == "selection" && page.answer_settings.only_one_option == "true" && !Forms::RoutesInput.too_many_selection_options?(page)
  end

  def initialize(attributes = {})
    @form = attributes.delete(:form)
    super
  end

  def submit
    return false if invalid?

    Routes::SyncService.new(form:, routes:).sync_conditions_from_routes

    form.save_draft!
    true
  end

  def assign_form_values
    self.routes = Routes::BuildService.new(form:).build_routes
    self
  end

  def routes_attributes=(attributes)
    page_ids = attributes.values.map { |attrs| attrs["page_id"] }.compact
    pages_by_id = form.pages.where(id: page_ids).index_by(&:id)

    route_build_service = Routes::BuildService.new(form:)
    goto_type = GotoValueType.new

    @routes = attributes.values.map { |route_attrs|
      page = pages_by_id[route_attrs["page_id"].to_i]
      next unless page # Skip if page not found or doesn't belong to form

      # Cast route_attrs["goto"] to a GotoValue object before using it
      # If goto is poitning to a page, we pass it in to the RouteInput now,
      # rather than needed to look it up later
      goto = goto_type.cast(route_attrs["goto"])
      goto_page = pages_by_id[goto.page_id] if goto.is_a?(GotoValue::Page)

      Forms::RouteInput.new(
        route_attrs.symbolize_keys.merge(
          page:,
          goto:,
          goto_page:,
          goto_options: route_build_service.options_for_goto_page(page, goto),
        ),
      )
    }.compact
  end

  def routes_are_valid
    return if routes.nil?

    routes.each.with_index do |route, index|
      next if route.valid?

      route.errors.each do |error|
        attribute_key = "routes_attributes[#{index}][#{error.attribute}]"
        error_field_id = field_id(:forms_routes_input_routes_attributes, error.attribute, index: index)

        errors.add(attribute_key, error.message, url: "##{error_field_id}")
      end
    end
  end
end
