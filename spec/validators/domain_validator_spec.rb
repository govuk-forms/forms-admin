require "rails_helper"

class DomainModel
  include ActiveModel::Validations
  attr_accessor :domain

  validates :domain, domain: true
end

RSpec.describe DomainValidator, type: :validator do
  context "when value is blank" do
    it "is valid" do
      model = DomainModel.new
      expect(model).to be_valid
    end
  end

  it_behaves_like "a domain validator" do
    let(:model) { DomainModel.new }
    let(:attribute) { :domain }
  end
end
