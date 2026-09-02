require "rails_helper"

RSpec.describe Forms::RoutesInput do
  subject(:routes_input) { described_class.new(form:) }

  let(:pages) { build_stubbed_list(:page, 2) }
  let(:form) { build_stubbed(:form, id: 1, pages:) }

  describe "#initialize" do
    it "assigns the form" do
      expect(routes_input.form).to eq(form)
    end
  end

  describe "#submit" do
    let(:sync_service_double) { instance_double(Routes::SyncService, sync_conditions_from_routes: true) }

    before do
      allow(Routes::SyncService).to receive(:new).and_return(sync_service_double)
      allow(form).to receive(:save_draft!)
    end

    it "calls the Routes::SyncService with the correct arguments" do
      routes_input.submit
      expect(Routes::SyncService).to have_received(:new).with(form:, routes: routes_input.routes)
    end

    it "calls sync_conditions_from_routes on the service" do
      routes_input.submit
      expect(sync_service_double).to have_received(:sync_conditions_from_routes)
    end

    it "returns true" do
      expect(routes_input.submit).to be true
    end
  end

  describe "#assign_form_values" do
    let(:built_routes) { [instance_double(Forms::RouteInput)] }
    let(:build_service_double) { instance_double(Routes::BuildService, build_routes: built_routes) }

    before do
      allow(Routes::BuildService).to receive(:new).and_return(build_service_double)
    end

    it "calls the Routes::BuildService with the form" do
      routes_input.assign_form_values
      expect(Routes::BuildService).to have_received(:new).with(form:)
    end

    it "assigns the result to the routes attribute" do
      routes_input.assign_form_values
      expect(routes_input.routes).to eq(built_routes)
    end

    it "returns self" do
      expect(routes_input.assign_form_values).to eq(routes_input)
    end
  end

  describe "#routes_attributes=" do
    let(:goto_options) { [["Go to page 2", pages.second.id]] }
    let(:route_build_service) { instance_double(Routes::BuildService, options_for_goto_page: goto_options) }
    let(:pages) { create_list(:page, 2) }
    let(:form) { create(:form, id: 1, pages:) }

    before do
      allow(Routes::BuildService).to receive(:new).with(form:).and_return(route_build_service)
      # allow Forms::RouteInput to be created and just return a simple object
      # so we can inspect what it was initialized with.
      allow(Forms::RouteInput).to receive(:new) { |args| OpenStruct.new(args) }
    end

    context "with valid attributes for existing pages" do
      let(:attributes) do
        {
          "0" => { "page_id" => pages.first.id.to_s, "goto" => "page_#{pages.second.id}" },
          "1" => { "page_id" => pages.second.id.to_s, "goto" => "page_1" },
        }
      end

      it "initializes a RouteInput for each valid page" do
        routes_input.routes_attributes = attributes
        expect(Forms::RouteInput).to have_received(:new).twice
      end

      it "initializes RouteInput with the correct page object and options" do
        routes_input.routes_attributes = attributes

        expect(Forms::RouteInput).to have_received(:new).with(
          page_id: pages.first.id.to_s,
          goto_page: pages.second,
          goto: GotoValue::Page.new(pages.second.id),
          page: pages.first,
          goto_options:,
        )
        expect(Forms::RouteInput).to have_received(:new).with(
          page_id: pages.second.id.to_s,
          goto_page: nil,
          goto: GotoValue::Page.new(1),
          page: pages.second,
          goto_options:,
        )
      end

      it "assigns the created RouteInput objects to routes" do
        routes_input.routes_attributes = attributes
        expect(routes_input.routes.length).to eq(2)
        expect(routes_input.routes.first.page).to eq(pages.first)
        expect(routes_input.routes.second.page).to eq(pages.second)
      end
    end

    context "with attributes containing a non-existent page_id" do
      let(:attributes) do
        {
          "0" => { "page_id" => pages.first.id.to_s },
          "1" => { "page_id" => "999" }, # This page ID does not exist on the form
        }
      end

      it "skips the invalid entry and only creates RouteInput for the valid one" do
        routes_input.routes_attributes = attributes

        expect(Forms::RouteInput).to have_received(:new).once
        expect(Forms::RouteInput).to have_received(:new).with(
          page_id: pages.first.id.to_s,
          page: pages.first,
          goto: nil,
          goto_page: nil,
          goto_options:,
        )
      end

      it "assigns only the valid RouteInput object to routes" do
        routes_input.routes_attributes = attributes
        expect(routes_input.routes.length).to eq(1)
        expect(routes_input.routes.first.page).to eq(pages.first)
      end
    end

    context "when a page_id is nil or blank" do
      let(:attributes) do
        {
          "0" => { "page_id" => pages.first.id.to_s },
          "1" => { "page_id" => nil },
        }
      end

      it "compacts the list and only includes valid routes" do
        routes_input.routes_attributes = attributes

        expect(routes_input.routes.length).to eq(1)
        expect(routes_input.routes.map(&:page)).to eq([pages.first])
      end
    end
  end

  describe "#routes_type" do
    context "when given a page with less than 10 selection options, only one option" do
      let(:page) { build(:page, :with_selection_settings) }

      it "returns :selection_options_routes" do
        expect(described_class.routes_type(page)).to eq :selection_options_routes
      end
    end

    context "when given a page with more than 10 selection options, only one option" do
      let(:page) { build(:page, :with_selection_settings, selection_options: (1..11).to_a.map { |i| { name: i.to_s, value: i.to_s } }) }

      it "returns :generic_route" do
        expect(described_class.routes_type(page)).to eq :generic_route
      end

      context "with existing conditions" do
        context "with selection options routes" do
          before do
            page.routing_conditions << build(
              :condition,
              routing_page: page,
              check_page: page,
              goto_page: build(:page, form: page.form),
              answer_value: "1",
            )
          end

          it "returns :existing_selection_options_routes" do
            expect(described_class.routes_type(page)).to eq :existing_selection_options_routes
          end
        end

        context "with generic route" do
          before do
            page.routing_conditions << build(
              :condition,
              routing_page: page,
              check_page: page,
              goto_page: build(:page, form: page.form),
              answer_value: nil,
            )
          end

          it "returns :generic_route" do
            expect(described_class.routes_type(page)).to eq :generic_route
          end
        end
      end
    end

    context "when given a selection page with checkboxes" do
      let(:page) { build(:page, :selection_with_checkboxes) }

      it "returns :generic_route" do
        expect(described_class.routes_type(page)).to eq :generic_route
      end
    end

    context "when given a page which isn't a selection type" do
      let(:page) { build(:page, :with_text_settings) }

      it "returns :generic_route" do
        expect(described_class.routes_type(page)).to eq :generic_route
      end
    end
  end

  describe "#route_with_selection_options?" do
    context "when given a page with less than 10 selection options, only one option" do
      let(:page) { build(:page, :with_selection_settings) }

      it "returns true" do
        expect(described_class.route_with_selection_options?(page)).to be true
      end
    end

    context "when given a page with more than 10 selection options, only one option" do
      let(:page) { build(:page, :with_selection_settings, selection_options: (1..11).to_a.map { |i| { name: i.to_s, value: i.to_s } }) }

      it "returns false" do
        expect(described_class.route_with_selection_options?(page)).to be false
      end

      context "with existing conditions" do
        context "with selection options routes" do
          before do
            page.routing_conditions << build(
              :condition,
              routing_page: page,
              check_page: page,
              goto_page: build(:page, form: page.form),
              answer_value: "1",
            )
          end

          it "returns true" do
            expect(described_class.route_with_selection_options?(page)).to be true
          end
        end

        context "with generic route" do
          before do
            page.routing_conditions << build(
              :condition,
              routing_page: page,
              check_page: page,
              goto_page: build(:page, form: page.form),
              answer_value: nil,
            )
          end

          it "returns false" do
            expect(described_class.route_with_selection_options?(page)).to be false
          end
        end
      end
    end

    context "when given a selection page with checkboxes" do
      let(:page) { build(:page, :selection_with_checkboxes) }

      it "returns false" do
        expect(described_class.route_with_selection_options?(page)).to be false
      end
    end

    context "when given a page which isn't a selection type" do
      let(:page) { build(:page, :with_text_settings) }

      it "returns false" do
        expect(described_class.route_with_selection_options?(page)).to be false
      end
    end
  end

  describe "#can_have_exit_pages?" do
    context "when given a page with less than 10 selection options, only one option" do
      let(:page) { build(:page, :with_selection_settings) }

      it "returns true" do
        expect(described_class.can_have_exit_pages?(page)).to be true
      end
    end

    context "when given a page with more than 10 selection options, only one option" do
      let(:page) { build(:page, :with_selection_settings, selection_options: (1..11).to_a.map { |i| { name: i.to_s, value: i.to_s } }) }

      it "returns false" do
        expect(described_class.can_have_exit_pages?(page)).to be false
      end

      context "with existing conditions" do
        context "with selection options routes" do
          before do
            page.routing_conditions << build(
              :condition,
              routing_page: page,
              check_page: page,
              goto_page: build(:page, form: page.form),
              answer_value: "1",
            )
          end

          it "returns true" do
            expect(described_class.can_have_exit_pages?(page)).to be true
          end
        end

        context "with generic route" do
          before do
            page.routing_conditions << build(
              :condition,
              routing_page: page,
              check_page: page,
              goto_page: build(:page, form: page.form),
              answer_value: nil,
            )
          end

          it "returns false" do
            expect(described_class.can_have_exit_pages?(page)).to be false
          end
        end
      end
    end

    context "when given a selection page with checkboxes" do
      let(:page) { build(:page, :selection_with_checkboxes) }

      it "returns false" do
        expect(described_class.can_have_exit_pages?(page)).to be false
      end
    end

    context "when given a page which isn't a selection type" do
      let(:page) { build(:page, :with_text_settings) }

      it "returns false" do
        expect(described_class.can_have_exit_pages?(page)).to be false
      end
    end
  end

  describe "#routes_are_valid" do
    before do
      routes_input.routes = routes
      routes_input.validate
    end

    context "when routes are valid" do
      let(:routes) { build_list(:route_input, 2) }

      it "is valid" do
        expect(routes_input).to be_valid
      end
    end

    context "when there are no routes" do
      let(:routes) { [] }

      it "is valid" do
        expect(routes_input).to be_valid
      end
    end

    context "when a route is invalid" do
      let(:routes) do
        [
          instance_double(
            Forms::RouteInput,
            valid?: false,
            errors: [instance_double(ActiveModel::Error, attribute: :goto, message: "a mock error")],
          ),
        ]
      end

      it "makes the parent object invalid" do
        expect(routes_input).to be_invalid
      end

      it "copies the error from the route" do
        expected_key = "routes_attributes[0][goto]".to_sym
        expect(routes_input.errors).to have_key(expected_key)
        expect(routes_input.errors.messages[expected_key]).to include("a mock error")
      end

      it "adds the URL" do
        expected_key = "routes_attributes[0][goto]".to_sym
        expected_url = "#forms_routes_input_routes_attributes_0_goto"

        error_detail = routes_input.errors.details[expected_key].first
        expect(error_detail).to have_key(:url)
        expect(error_detail[:url]).to eq(expected_url)
      end
    end
  end
end
