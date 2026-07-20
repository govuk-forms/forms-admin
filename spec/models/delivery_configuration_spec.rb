require "rails_helper"

RSpec.describe DeliveryConfiguration, type: :model do
  describe "factory" do
    it "has a valid factory" do
      expect(build(:delivery_configuration)).to be_valid
    end

    it "is invalid without a form" do
      delivery_configuration = build(:delivery_configuration, form: nil)

      expect(delivery_configuration).not_to be_valid
    end
  end

  describe "traits" do
    it "builds a batch email configuration" do
      delivery_configuration = build(:delivery_configuration, :batch_email)

      expect(delivery_configuration.delivery_method).to eq("email")
      expect(delivery_configuration.formats).to eq(%w[csv])
      expect(delivery_configuration.delivery_schedule).to eq("immediate")
    end

    it "builds a daily email configuration" do
      delivery_configuration = build(:delivery_configuration, :daily_email)

      expect(delivery_configuration.delivery_method).to eq("email")
      expect(delivery_configuration.formats).to eq(%w[csv])
      expect(delivery_configuration.delivery_schedule).to eq("daily")
    end

    it "builds a weekly email configuration" do
      delivery_configuration = build(:delivery_configuration, :weekly_email)

      expect(delivery_configuration.delivery_method).to eq("email")
      expect(delivery_configuration.formats).to eq(%w[csv])
      expect(delivery_configuration.delivery_schedule).to eq("weekly")
    end

    it "builds an s3 configuration" do
      delivery_configuration = build(:delivery_configuration, :s3)

      expect(delivery_configuration.delivery_method).to eq("s3")
      expect(delivery_configuration.delivery_schedule).to eq("immediate")
      expect(delivery_configuration.formats).to eq(%w[csv])
    end
  end

  describe "validations" do
    it "is valid with valid formats" do
      delivery_configuration = build(:delivery_configuration, formats: %w[csv json])

      expect(delivery_configuration).to be_valid
    end

    it "is valid with an empty formats array" do
      delivery_configuration = build(:delivery_configuration, formats: [])

      expect(delivery_configuration).to be_valid
    end

    it "is invalid with an invalid format" do
      delivery_configuration = build(:delivery_configuration, formats: %w[csv xml])

      expect(delivery_configuration).not_to be_valid
    end
  end
end
