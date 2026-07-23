class ExitPage < ApplicationRecord
  extend Mobility
  belongs_to :question_page, class_name: "Page", optional: true

  validates :heading, presence: true, on: :complete
  validates :markdown, presence: true, on: :complete

  translates :heading, :markdown

  def as_form_document_exit_page
    {
      "id" => id,
      "heading" => heading,
      "markdown" => markdown,
    }
  end
end
