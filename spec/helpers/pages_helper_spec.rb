require "rails_helper"

RSpec.describe PagesHelper, type: :helper do
  let(:page_id) { 2 }
  let(:draft_question) { build :draft_question, page_id: }

  describe "#selection_options_new_path_for_draft_question" do
    context "when draft_question has no answer_settings" do
      it "returns options path" do
        expect(helper.selection_options_new_path_for_draft_question(draft_question))
          .to eq(selection_options_new_path(form_id: draft_question.form_id))
      end
    end

    context "when draft_question has 30 selection options" do
      let(:selection_options) { (1..30).to_a.map { |i| { name: i.to_s } } }
      let(:draft_question) { build :draft_question, answer_settings: { selection_options: } }

      it "returns options path" do
        expect(helper.selection_options_new_path_for_draft_question(draft_question))
          .to eq(selection_options_new_path(form_id: draft_question.form_id))
      end
    end

    context "when draft_question has more than 30 selection options" do
      let(:selection_options) { (1..31).to_a.map { |i| { name: i.to_s } } }
      let(:draft_question) { build :draft_question, answer_settings: { selection_options: } }

      it "returns bulk options path" do
        expect(helper.selection_options_new_path_for_draft_question(draft_question))
          .to eq(selection_bulk_options_new_path(form_id: draft_question.form_id))
      end
    end
  end

  describe "#selection_options_edit_path_for_draft_question" do
    context "when draft_question has no answer_settings" do
      it "returns options path" do
        expect(helper.selection_options_edit_path_for_draft_question(draft_question))
          .to eq(selection_options_edit_path(form_id: draft_question.form_id, page_id:))
      end
    end

    context "when draft_question has 30 selection options" do
      let(:selection_options) { (1..30).to_a.map { |i| { name: i.to_s } } }
      let(:draft_question) { build :draft_question, page_id:, answer_settings: { selection_options: } }

      it "returns options path" do
        expect(helper.selection_options_edit_path_for_draft_question(draft_question))
          .to eq(selection_options_edit_path(form_id: draft_question.form_id, page_id:))
      end
    end

    context "when draft_question has more than 30 selection options" do
      let(:selection_options) { (1..31).to_a.map { |i| { name: i.to_s } } }
      let(:draft_question) { build :draft_question, page_id:, answer_settings: { selection_options: } }

      it "returns bulk options path" do
        expect(helper.selection_options_edit_path_for_draft_question(draft_question))
          .to eq(selection_bulk_options_edit_path(form_id: draft_question.form_id, page_id:))
      end
    end
  end

  describe "#has_more_than_30_options?" do
    context "when draft_question has no answer_settings" do
      it "returns false" do
        expect(helper.has_more_than_30_options?(draft_question)).to be false
      end
    end

    context "when draft_question has 30 selection options" do
      let(:selection_options) { (1..30).to_a.map { |i| { name: i.to_s } } }
      let(:draft_question) { build :draft_question, answer_settings: { selection_options: } }

      it "returns false" do
        expect(helper.has_more_than_30_options?(draft_question)).to be false
      end
    end

    context "when draft_question has more than 30 selection options" do
      let(:selection_options) { (1..31).to_a.map { |i| { name: i.to_s } } }
      let(:draft_question) { build :draft_question, answer_settings: { selection_options: } }

      it "returns true" do
        expect(helper.has_more_than_30_options?(draft_question)).to be true
      end
    end
  end

  describe "#selection_options_in_routes_banner" do
    let(:form) { create :form, :with_group, :ready_for_routing, group: create(:group, multiple_branches_enabled:) }
    let(:multiple_branches_enabled) { true }
    let(:draft_question) { build :selection_draft_question, form_id: form.id, page_id: form.pages.first.id }
    let(:selection_options_with_value) { (1..3).to_a.map { |i| { name: i.to_s } } }
    let(:include_none_of_the_above) { false }

    context "when draft_question has no answer_settings" do
      it "returns nil" do
        expect(helper.selection_options_in_routes_banner(draft_question, selection_options_with_value, include_none_of_the_above)).to be_nil
      end
    end

    context "when multiple_branches_enabled is false" do
      let(:selection_options_with_value) { [{ name: "Option 1", value: "Option 1" }] }
      let(:multiple_branches_enabled) { false }

      before do
        create(:condition, answer_value: "Option 1", routing_page_id: form.pages.first.id)
      end

      it "returns nil" do
        expect(helper.selection_options_in_routes_banner(draft_question, selection_options_with_value, include_none_of_the_above)).to be_nil
      end
    end

    context "when a single option is used in a condition" do
      let(:selection_options_with_value) { [{ name: "Option 1", value: "Option 1" }] }

      before do
        create(:condition, answer_value: "Option 1", routing_page_id: form.pages.first.id)
      end

      it "returns a banner with the correct text" do
        result = helper.selection_options_in_routes_banner(draft_question, selection_options_with_value, include_none_of_the_above)
        expect(result[:heading]).to eq("There is a route from option 1")
        expect(result[:text]).to eq("If you remove or change option 1, the route will be deleted. <a class=\"govuk-link\" href=\"/forms/#{form.id}/routes\">View your question routes</a>")
      end

      it "retuns the correct text when using :answer_value option index" do
        result = helper.selection_options_in_routes_banner(draft_question, selection_options_with_value, include_none_of_the_above, option_indexes: :answer_value)
        expect(result[:heading]).to eq("There is a route from ‘Option 1’")
        expect(result[:text]).to eq("If you remove or change this option, the route will be deleted. <a class=\"govuk-link\" href=\"/forms/#{form.id}/routes\">View your question routes</a>")
        # "If you remove or change option this option, the route will be deleted. <a class=\"govuk-link\" href=\"/forms/34362/routes\">View your question routes</a>
      end
    end

    context "when there is a single option which is none of the above" do
      let(:selection_options) { [] }
      let(:include_none_of_the_above) { true }

      before do
        create(:condition, answer_value: Condition::NONE_OF_THE_ABOVE, routing_page_id: form.pages.first.id)
      end

      it "returns a banner with the correct text" do
        result = helper.selection_options_in_routes_banner(draft_question, selection_options, include_none_of_the_above)
        expect(result[:heading]).to eq("There is a route from ‘None of the above’")
        expect(result[:text]).to eq("If you remove ‘None of the above’, the route will be deleted. <a class=\"govuk-link\" href=\"/forms/#{form.id}/routes\">View your question routes</a>")
      end
    end

    context "when all options are in conditions" do
      let(:selection_options_with_value) { [{ name: "Option 1", value: "Option 1" }, { name: "Option 2", value: "Option 2" }] }

      before do
        create(:condition, answer_value: "Option 1", routing_page_id: form.pages.first.id)
        create(:condition, answer_value: "Option 2", routing_page_id: form.pages.first.id)
      end

      it "returns a banner with the correct text" do
        result = helper.selection_options_in_routes_banner(draft_question, selection_options_with_value, include_none_of_the_above)
        expect(result[:heading]).to eq("There are routes from these options")
        expect(result[:text]).to eq("If you remove or change an option with a route, the route will be deleted. <a class=\"govuk-link\" href=\"/forms/#{form.id}/routes\">View your question routes</a>")
      end
    end

    context "when some options are in conditions" do
      let(:selection_options_with_value) { [{ name: "Option 1", value: "Option 1" }, { name: "Option 2", value: "Option 2" }, { name: "Option 3", value: "Option 3" }] }

      before do
        create(:condition, answer_value: "Option 1", routing_page_id: form.pages.first.id)
        create(:condition, answer_value: "Option 3", routing_page_id: form.pages.first.id)
      end

      it "returns a banner with the correct text" do
        result = helper.selection_options_in_routes_banner(draft_question, selection_options_with_value, include_none_of_the_above)
        expect(result[:heading]).to eq("There are routes from some of these options")
        expect(result[:text]).to eq("If you remove or change an option with a route, the route will be deleted. <a class=\"govuk-link\" href=\"/forms/#{form.id}/routes\">View your question routes</a>")
      end
    end
  end

  describe "#routes_and_exit_pages" do
    subject(:routes_and_exit_pages) { helper.routes_and_exit_pages(page) }

    let(:page) { build_stubbed :page, routing_conditions:, goto_conditions:, exit_pages: }
    let(:routing_conditions) { [] }
    let(:goto_conditions) { [] }
    let(:exit_pages) { [] }

    context "when page has no routes and no exit pages" do
      let(:routing_conditions) { [] }
      let(:exit_pages) { [] }

      it { is_expected.to eq "" }
    end

    context "when page has one route and no exit pages" do
      let(:routing_conditions) { [build_stubbed(:condition)] }
      let(:exit_pages) { [] }

      it { is_expected.to eq "route" }
    end

    context "when page has multiple routes and no exit pages" do
      let(:routing_conditions) { build_stubbed_list(:condition, 2) }
      let(:exit_pages) { [] }

      it { is_expected.to eq "routes" }
    end

    context "when page has no routes and one exit page" do
      let(:routing_conditions) { [] }
      let(:exit_pages) { [build_stubbed(:exit_page)] }

      it { is_expected.to eq "exit page" }
    end

    context "when page has no routes and multiple exit pages" do
      let(:routing_conditions) { [] }
      let(:exit_pages) { build_stubbed_list(:exit_page, 2) }

      it { is_expected.to eq "exit pages" }
    end

    context "when page has one route and one exit page" do
      let(:routing_conditions) { [build_stubbed(:condition)] }
      let(:exit_pages) { [build_stubbed(:exit_page)] }

      it { is_expected.to eq "route and exit page" }
    end

    context "when page has multiple routes and one exit page" do
      let(:routing_conditions) { build_stubbed_list(:condition, 2) }
      let(:exit_pages) { [build_stubbed(:exit_page)] }

      it { is_expected.to eq "routes and exit page" }
    end

    context "when page has multiple routes and multiple exit pages" do
      let(:routing_conditions) { build_stubbed_list(:condition, 2) }
      let(:exit_pages) { build_stubbed_list(:exit_page, 2) }

      it { is_expected.to eq "routes and exit pages" }
    end

    context "when count_goto_conditions is false" do
      subject(:routes_and_exit_pages) { helper.routes_and_exit_pages(page, count_goto_conditions: false) }

      context "when page has no routing conditions and no goto conditions" do
        let(:routing_conditions) { [] }
        let(:goto_conditions) { [] }

        it { is_expected.to eq "" }
      end

      context "when page has no routing conditions and one goto condition" do
        let(:routing_conditions) { [] }
        let(:goto_conditions) { [build_stubbed(:condition)] }

        it { is_expected.to eq "" }
      end

      context "when page has one routing condition and no goto conditions" do
        let(:routing_conditions) { [build_stubbed(:condition)] }
        let(:goto_conditions) { [] }

        it { is_expected.to eq "route" }
      end

      context "when page has one routing condition and one goto condition" do
        let(:routing_conditions) { [build_stubbed(:condition)] }
        let(:goto_conditions) { [build_stubbed(:condition)] }

        it { is_expected.to eq "route" }
      end
    end

    context "when count_goto_conditions is true" do
      subject(:routes_and_exit_pages) { helper.routes_and_exit_pages(page, count_goto_conditions: true) }

      context "when page has no routing conditions and no goto conditions" do
        let(:routing_conditions) { [] }
        let(:goto_conditions) { [] }

        it { is_expected.to eq "" }
      end

      context "when page has no routing conditions and one goto condition" do
        let(:routing_conditions) { [] }
        let(:goto_conditions) { [build_stubbed(:condition)] }

        it { is_expected.to eq "route" }
      end

      context "when page has one routing condition and no goto conditions" do
        let(:routing_conditions) { [build_stubbed(:condition)] }
        let(:goto_conditions) { [] }

        it { is_expected.to eq "route" }
      end

      context "when page has one routing condition and one goto condition" do
        let(:routing_conditions) { [build_stubbed(:condition)] }
        let(:goto_conditions) { [build_stubbed(:condition)] }

        it { is_expected.to eq "routes" }
      end
    end
  end
end
