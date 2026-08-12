class Pages::ExitPageInput < BaseInput
  attr_accessor :page, :markdown, :heading

  include ExitPageValidation

  def submit
    return false if invalid?

    ExitPage.create!(question_page: page, heading:, markdown:)
  end
end
