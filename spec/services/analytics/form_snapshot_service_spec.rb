require "rails_helper"

RSpec.describe Analytics::FormSnapshotService do
  subject(:rows) { described_class.new(snapshot_at: Time.utc(2026, 10, 28, 22)).rows }

  def row_for(form)
    rows.find { |row| row[:form_id] == form.id.to_s }
  end

  it "returns a row for each form" do
    organisation = create(:organisation)
    form = create(:form, :live, :with_group, group: create(:group, organisation:))

    expect(row_for(form)).to include(
      snapshot_at: "2026-10-28T22:00:00.000Z",
      organisation_id: organisation.id.to_s,
      state: "live",
      properties: a_string_including('"payment":false'),
    )
  end

  it "includes forms with no group" do
    form = create(:form)

    expect(row_for(form)).to include(organisation_id: nil, state: "draft")
  end

  it "leaves out forms in internal organisations" do
    form = create(:form, :live, :with_group, group: create(:group, organisation: create(:organisation, internal: true)))

    expect(row_for(form)).to be_nil
  end

  it "takes the features of a live form with a draft from the live version" do
    form = create(:form, :live_with_draft)
    form.update!(payment_url: "https://www.gov.uk/payments/organisation/service")

    expect(row_for(form)[:properties]).to include('"payment":false')
  end
end
