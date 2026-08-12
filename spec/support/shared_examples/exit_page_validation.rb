RSpec.shared_examples "validates exit pages" do
  it "is invalid if heading is nil" do
    model.heading = nil
    expect(model).to be_invalid
    expect(model.errors.where(:heading, :blank)).to be_present
  end

  it "is invalid if markdown is nil" do
    exit_page_input.markdown = nil
    expect(exit_page_input).to be_invalid
    expect(model.errors.where(:markdown, :blank)).to be_present
  end

  it "is invalid if heading is too long" do
    exit_page_input.heading = "a" * 251
    expect(exit_page_input).to be_invalid
    expect(model.errors.where(:heading, :too_long)).to be_present
  end

  it_behaves_like "a markdown field with headings allowed" do
    let(:attribute) { :markdown }
  end
end
