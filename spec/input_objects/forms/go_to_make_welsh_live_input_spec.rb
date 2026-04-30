require "rails_helper"

RSpec.describe Forms::GoToMakeWelshLiveInput, type: :model do
  it "is invalid if blank" do
    confirm_archive_input = described_class.new(confirm: "")
    confirm_archive_input.validate(:confirm)

    expect(confirm_archive_input.errors.full_messages_for(:confirm)).to include(
      "Confirm Select ‘Yes’ if you want to make your Welsh form live",
    )
  end
end
