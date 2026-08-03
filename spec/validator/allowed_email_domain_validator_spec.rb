require "rails_helper"

class AllowedEmailDomainModel
  include ActiveModel::Validations
  attr_accessor :email

  validates :email, allowed_email_domain: true
end

class AllowedEmailDomainModelWithCurrentUser
  include ActiveModel::Model
  attr_accessor :current_user, :email

  validates :email, allowed_email_domain: true
end

class AllowedEmailDomainModelWithForm
  include ActiveModel::Model
  attr_accessor :form, :email

  validates :email, allowed_email_domain: true
end

RSpec.describe AllowedEmailDomainValidator do
  let(:model) { AllowedEmailDomainModel.new }

  it "validates email with .gov.uk" do
    model.email = "test.gov.uk"
    expect(model).to be_valid
  end

  it "validates email with .gov.scot" do
    model.email = "test.gov.scot"
    expect(model).to be_valid
  end

  it "validates email with .gov.wales" do
    model.email = "test.gov.wales"
    expect(model).to be_valid
  end

  it "validates email with .mod.uk" do
    model.email = "test.mod.uk"
    expect(model).to be_valid
  end

  it "does not validate any non-govuk email" do
    model.email = "test@example.com"
    expect(model).to be_invalid
  end

  context "with model with a form" do
    let(:form) { create(:form, :with_group) }
    let(:model) { AllowedEmailDomainModelWithForm.new(form:) }

    before do
      create(:organisation_domain, organisation: form.group.organisation, domain: "somewhere.gov.uk")
      create(:organisation_domain, organisation: form.group.organisation, domain: "ogd.example")
    end

    it "does not validate any non-govuk email" do
      model.email = "test@example.com"
      expect(model).to be_invalid
    end

    it "validates email with domain associated with organisation" do
      model.email = "b@ogd.example"
      expect(model).to be_valid
    end

    it "does not validate email with sub-domain of domain associated with organisation" do
      model.email = "b@sub.ogd.example"
      expect(model).to be_invalid
    end

    it "does not validate email that contains a domain associated with the organisation" do
      model.email = "b@notogd.example"
      expect(model).to be_invalid
    end
  end
end
