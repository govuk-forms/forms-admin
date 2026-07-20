require "rails_helper"

RSpec.describe "organisation factory" do
  it "does not persist the organisation" do
    org = build :organisation

    expect(org).not_to be_persisted
  end
end
