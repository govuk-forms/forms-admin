RSpec.shared_examples "implements condition methods" do
  describe "#is_exit_page?" do
    it "returns false when exit_page_markdown is nil" do
      subject.exit_page_markdown = nil
      subject.exit_page_id = nil
      expect(subject.is_exit_page?).to be false
    end

    it "returns true when exit_page_markdown is not nil" do
      subject.exit_page_markdown = ""
      subject.exit_page_id = nil
      expect(subject.is_exit_page?).to be true
    end

    it "returns true when exit_page_id is present" do
      subject.exit_page_markdown = nil
      subject.exit_page_id = 1
      expect(subject.is_exit_page?).to be true
    end
  end

  describe "#secondary_skip?" do
    it "returns false when the answer value is not blank" do
      subject.answer_value = "something"
      subject.check_page_id = 1
      subject.routing_page_id = 3
      expect(subject.secondary_skip?).to be false
    end

    it "returns false when the check page id and routing page id are the same" do
      subject.answer_value = nil
      subject.check_page_id = 1
      subject.routing_page_id = 1
      expect(subject.secondary_skip?).to be false
    end

    it "returns true when there is no answer value and the check page and routing page ids are the same" do
      subject.answer_value = nil
      subject.check_page_id = 1
      subject.routing_page_id = 3
      expect(subject.secondary_skip?).to be true
    end
  end
end
