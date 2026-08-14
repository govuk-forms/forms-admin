class Pages::UpdateExitPageInput < BaseInput
  attr_accessor :page, :markdown, :heading, :exit_page

  include ExitPageValidation

  def assign_exit_page_values
    self.page = exit_page.question_page
    self.heading = exit_page.heading
    self.markdown = exit_page.markdown

    self
  end

  def submit
    return false if invalid?

    page.form.save_question_changes! do
      exit_page.update!(heading: heading, markdown: markdown)
    end
  end
end
