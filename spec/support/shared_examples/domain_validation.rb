RSpec.shared_examples "a domain validator" do
  context "with a valid domain" do
    %w[example.com sub.example.gov.wales EXAMPLE.COM a-b.example].each do |domain|
      context "when domain is '#{domain}'" do
        it "is valid" do
          model.send("#{attribute}=", domain)

          expect(model).to be_valid
        end
      end
    end
  end

  context "with invalid domain" do
    %w[http://example.com ex_ample.com example..com -example.com example-.com @example.com .example.com].each do |domain|
      context "when domain is '#{domain}'" do
        it "is invalid" do
          model.send("#{attribute}=", domain)

          expect(model).to be_invalid
          expect(model.errors.details[:domain].first[:error]).to eq(:invalid_domain)
        end
      end
    end
  end
end
