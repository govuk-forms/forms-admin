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

  def position
    question_page.exit_pages.order(:created_at).pluck(:id).index(id).to_i + 1
  end

  def self.positions_for_page(question_page)
    question_page.exit_pages.order(:created_at).pluck(:id).each_with_index.to_h do |exit_page_id, index|
      [exit_page_id, index + 1]
    end
  end
end
