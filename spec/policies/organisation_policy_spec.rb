require "rails_helper"

describe OrganisationPolicy do
  subject(:policy) { described_class.new(user, :organisation) }

  let(:user) { build :super_admin_user }

  context "with super admin" do
    it { is_expected.to permit_actions(%i[can_view_organisations]) }
  end

  (User.roles.keys - %w[super_admin]).each do |role|
    context "with #{role}" do
      let(:user) { build :user, role: }

      it { is_expected.to forbid_actions(%i[can_view_organisations]) }
    end
  end
end
