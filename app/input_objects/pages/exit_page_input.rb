class Pages::ExitPageInput < BaseInput
  attr_accessor :page, :markdown, :heading

  validates :heading, :markdown, presence: true
  validates :heading, length: { maximum: 250 }
  validates :markdown, markdown: { allow_headings: true }

  def submit
    return false if invalid?

    ExitPage.create!(question_page: page, heading:, markdown:)
  end
end
