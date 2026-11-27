require "rails_helper"

class TestController
  include AfterSignInPathHelper
  include Rails.application.routes.url_helpers

  attr_reader :current_user, :stored_location

  def initialize(current_user, stored_location)
    @current_user = current_user
    @stored_location = stored_location
  end
end

describe AfterSignInPathHelper do
  include Rails.application.routes.url_helpers

  subject(:test_controller) do
    TestController.new(user, location)
  end

  let(:user) { build :user }
  let(:location) { "/default" }

  describe "#after_sign_in_next_path" do
    context "when the user's account is complete" do
      it "returns the default path" do
        expect(test_controller.after_sign_in_next_path).to eq location
      end
    end

    context "when the user has not agreed to the terms of use" do
      let(:user) { build :user, terms_agreed_at: nil }

      it "returns the path to agree to the terms of use" do
        expect(test_controller.after_sign_in_next_path).to eq edit_account_terms_of_use_path
      end
    end

    context "when the stored_location is nil" do
      let(:location) { nil }

      it "returns the root path" do
        expect(test_controller.after_sign_in_next_path).to eq root_path
      end
    end
  end
end
