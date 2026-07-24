class ExitPage < ApplicationRecord
  extend Mobility
  belongs_to :question_page, class_name: "Page", optional: false
  has_many :conditions, class_name: "Condition", dependent: :nullify

  validates :heading, presence: true
  validates :markdown, presence: true

  translates :heading, :markdown

  def as_form_document_exit_page
    {
      "id" => id,
      "heading" => heading,
      "markdown" => markdown,
    }
  end
end
