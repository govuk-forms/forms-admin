require "rails_helper"

RSpec.describe FormDocument::Condition, type: :model do
  subject(:form_document_condition) { described_class.new(condition_as_form_document_condition) }

  let(:condition) { create :condition }
  let(:condition_as_form_document_condition) { condition.as_form_document_condition }

  it "ignores any attributes that are not defined" do
    expect(described_class.new(foo: "bar").attributes).not_to include(:foo)
  end

  it "has all the attributes the original condition has" do
    expect(form_document_condition.attributes.except("routing_page_id")).to include(condition.attributes.except("routing_page_id", "exit_page_id"))
    expect(form_document_condition.routing_page_id).to eq(condition.routing_page.external_id)
  end

  it "has a validation_errors attribute" do
    expect(form_document_condition.validation_errors).to eq(condition.validation_errors)
  end

  it_behaves_like "implements condition methods"
end
