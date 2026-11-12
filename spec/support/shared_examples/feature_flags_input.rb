# Expects `record` (saved with `feature_flag` off), `record_name` and `feature_flag` to be defined.
RSpec.shared_examples "a feature flags input" do
  def build_input(attributes = {})
    described_class.new({ record_name => record, **attributes })
  end

  describe "#assign_values" do
    it "copies the record's flag values onto the input" do
      record.update!(feature_flag => true)

      input = build_input.assign_values

      expect(input.public_send(feature_flag)).to be(true)
    end
  end

  describe "#submit" do
    it "enables a flag submitted as true" do
      input = build_input(feature_flag => "true")

      expect(input.submit).to be(true)
      expect(record.reload[feature_flag]).to be(true)
    end

    it "does not turn a flag off when submitted as false" do
      record.update!(feature_flag => true)

      input = build_input(feature_flag => "false")

      expect(input.submit).to be(true)
      expect(record.reload[feature_flag]).to be(true)
    end

    context "when the record cannot be saved" do
      let(:input) { build_input(feature_flag => "true") }

      before do
        allow(record).to receive(:save).and_return(false)
      end

      it "returns false and leaves the record's flag unchanged" do
        expect(input.submit).to be(false)
        expect(record[feature_flag]).to be(false)
      end
    end
  end

  describe "#flag_locked?" do
    it "is true when the flag is saved as on" do
      record.update!(feature_flag => true)

      expect(build_input.flag_locked?(feature_flag)).to be(true)
    end

    it "is false when the flag has only been turned on in memory" do
      record.assign_attributes(feature_flag => true)

      expect(build_input.flag_locked?(feature_flag)).to be(false)
    end
  end

  describe "#flag_checked?" do
    it "is true when the flag is saved as on, even if submitted as false" do
      record.update!(feature_flag => true)

      input = build_input(feature_flag => "false")

      expect(input.flag_checked?(feature_flag)).to be(true)
    end

    it "is true when the flag is submitted as true" do
      input = build_input(feature_flag => "true")

      expect(input.flag_checked?(feature_flag)).to be(true)
    end

    it "is false when the flag is off and not submitted" do
      expect(build_input.flag_checked?(feature_flag)).to be(false)
    end
  end

  describe "#flags_changed?" do
    it "is true when submitting enabled a flag" do
      input = build_input(feature_flag => "true")
      input.submit

      expect(input.flags_changed?).to be(true)
    end

    it "is false when submitting made no changes" do
      record.update!(feature_flag => true)

      input = build_input(feature_flag => "true")
      input.submit

      expect(input.flags_changed?).to be(false)
    end
  end
end
