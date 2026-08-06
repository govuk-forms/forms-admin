class Conditions::ExitPageInput < BaseInput
  attr_accessor :form, :page, :record, :exit_page_markdown, :exit_page_heading, :answer_value

  validates :exit_page_heading, :exit_page_markdown, :answer_value, presence: true
  validates :exit_page_heading, length: { maximum: 250 }
  validates :exit_page_markdown, markdown: { allow_headings: true }

  def submit
    return false if invalid?

    Condition.create_and_update_form!(
      check_page_id: page.id,
      routing_page_id: page.id,
      answer_value:,
      goto_page_id: nil,
      skip_to_end: nil,
      exit_page_heading:,
      exit_page_markdown:,
    )
  end
end
