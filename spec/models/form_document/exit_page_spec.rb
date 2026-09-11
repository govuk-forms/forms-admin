require "rails_helper"

RSpec.describe FormDocument::ExitPage, type: :model do
  subject(:form_document_exit_page) { described_class.new(page_as_form_document_exit_page) }

  let(:exit_page) { create :exit_page }
  let(:page_as_form_document_exit_page) { exit_page.as_form_document_exit_page }

  it "ignores any attributes that are not defined" do
    expect(described_class.new(foo: "bar").attributes).not_to include(:foo)
  end

  it "has all exit page attributes the original exit page has" do
    expect(form_document_exit_page).to have_attributes(
      id: exit_page.id,
      heading: exit_page.heading,
      markdown: exit_page.markdown,
    )
  end
end
