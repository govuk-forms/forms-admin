require "rails_helper"

RSpec.describe Forms::RouteInput, type: :model do
  subject(:route_input) { described_class.new(attributes) }

  let(:check_your_answers_value) { GotoValue::EndOfFormValue.new }
  let(:default_value) { GotoValue::DefaultValue.new }

  let(:page) { build_stubbed(:page, position: 1) }
  let(:goto_page) { build_stubbed(:page, position: 2) }

  let(:attributes) do
    {
      id: 1,
      page_id: page.id,
      goto: "page_#{goto_page.id}",
      answer_value: "Yes",
      page: page,
      goto_page: goto_page,
    }
  end

  it "has a valid factory" do
    expect(build(:route_input)).to be_valid
  end

  describe "attributes" do
    it "can be initialized with a hash of attributes" do
      expect(route_input.id).to eq(1)
      expect(route_input.page_id).to eq(page.id)
      expect(route_input.goto).to eq(GotoValue::Page.new(goto_page.id))
      expect(route_input.answer_value).to eq("Yes")
      expect(route_input.page).to eq(page)
    end
  end

  describe "#goes_to_default_next_page?" do
    context "when goto is the default value symbol" do
      it "returns true" do
        route_input.goto = default_value
        expect(route_input.goes_to_default_next_page?).to be true
      end
    end

    context "when goto is the default value string" do
      it "returns true" do
        route_input.goto = default_value.to_s
        expect(route_input.goes_to_default_next_page?).to be true
      end
    end

    context "when goto is some other value" do
      it "returns false" do
        route_input.goto = "page_123"
        expect(route_input.goes_to_default_next_page?).to be false
      end
    end
  end

  describe "#goes_to_end_of_form?" do
    context "when goto is the check_your_answers symbol" do
      it "returns true" do
        route_input.goto = check_your_answers_value
        expect(route_input.goes_to_end_of_form?).to be true
      end
    end

    context "when goto is the check_your_answers string" do
      it "returns true" do
        route_input.goto = check_your_answers_value.to_s
        expect(route_input.goes_to_end_of_form?).to be true
      end
    end

    context "when goto is some other value" do
      it "returns false" do
        route_input.goto = "page_456"
        expect(route_input.goes_to_end_of_form?).to be false
      end
    end
  end

  describe "#goes_to_exit?" do
    context "when goto is an exit page" do
      it "returns true" do
        route_input.goto = "exit_page_123"
        expect(route_input.goes_to_exit?).to be true
      end
    end

    context "when goto is not an exit page" do
      it "returns false" do
        route_input.goto = "page_123"
        expect(route_input.goes_to_exit?).to be false
      end
    end
  end

  describe "#condition_attributes" do
    it "returns nil if the route is to the default next page" do
      route_input.goto = default_value
      expect(route_input.condition_attributes).to be_nil
    end

    it "returns skip_to_end: true if the route is to the end of the form" do
      route_input.goto = check_your_answers_value
      expect(route_input.condition_attributes).to eq({ goto_page_id: nil, skip_to_end: true, check_page_id: page.id })
    end

    it "returns the correct attributes if the route is to a different page" do
      route_input.goto = GotoValue::Page.new(123)
      expect(route_input.condition_attributes).to eq(
        { goto_page_id: 123, skip_to_end: false, check_page_id: page.id },
      )
    end

    it "returns attributes for an exit page" do
      route_input.goto = GotoValue::ExitPage.new(999)
      expect(route_input.condition_attributes).to eq(
        { goto_page_id: nil, skip_to_end: false, check_page_id: page.id, exit_page_id: 999 },
      )
    end
  end

  describe "#label_text" do
    context "when the route is to the next page" do
      it "returns the correct label" do
        expect(route_input.label_text).to eq("After question 1, go to:")
      end
    end

    context "when the route is for a generic page" do
      let(:middle_page) { build_stubbed(:page, position: 2) }
      let(:goto_page) { build_stubbed(:page, position: 3) }

      it "sets the label correctly for a generic page" do
        expect(route_input.label_text).to eq("After question 1, go to:")
      end
    end

    context "when the route is for a selection page" do
      let(:page) { build_stubbed(:page, :with_selection_settings, position: 1) }
      let(:goto_page) { build_stubbed(:page, position: 2) }
      let(:attributes) { super().merge(answer_value: "Option 1") }

      it "sets the label correctly for a selection page" do
        expect(route_input.label_text).to eq("If option 1 (Option 1), go to:")
      end
    end

    context "when the route is for a selection page with a none of the above option" do
      let(:page) { build_stubbed(:page, :with_selection_settings, position: 1) }
      let(:goto_page) { build_stubbed(:page, position: 2) }
      let(:attributes) { super().merge(answer_value: Condition::NONE_OF_THE_ABOVE) }

      it "sets the label correctly for a selection page with a none of the above option" do
        expect(route_input.label_text).to eq("If option 3 (None of the above), go to:")
      end
    end
  end

  describe "#route_is_not_backwards" do
    context "when the route is not backwards" do
      let(:page) { build_stubbed(:page, position: 1) }
      let(:goto_page) { build_stubbed(:page, position: 2) }

      it "does not add an error" do
        expect(route_input).to be_valid
      end
    end

    context "when the route is backwards" do
      let(:page) { build_stubbed(:page, position: 2) }
      let(:goto_page) { build_stubbed(:page, position: 1) }

      it "adds the correct error" do
        expect(route_input).to be_invalid
        expect(route_input.errors[:goto]).to eq(["The route from question 2 cannot go to a previous question - edit this route"])
      end

      context "when the route is for a selection question" do
        let(:page) { build_stubbed(:page, :with_selection_settings, position: 2) }
        let(:attributes) { super().merge(answer_value: "Option 1") }

        it "adds the correct error" do
          expect(route_input).to be_invalid
          expect(route_input.errors[:goto]).to eq(["The route from question 2, option 1 cannot go to a previous question - edit this route"])
        end
      end

      it "doesn't add an error for a default route" do
        route_input.goto = default_value
        expect(route_input).to be_valid
      end

      it "doesn't add an error for an end of form route" do
        route_input.goto = check_your_answers_value
        expect(route_input).to be_valid
      end

      it "doesn't add an error when not goto_page is set" do
        route_input.goto_page = nil
        expect(route_input).to be_valid
      end
    end
  end
end
