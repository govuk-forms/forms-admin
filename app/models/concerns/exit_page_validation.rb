module ExitPageValidation
  extend ActiveSupport::Concern

  included do
    validates :heading, :markdown, presence: true
    validates :heading, length: { maximum: 250 }
    validates :markdown, markdown: { allow_headings: true }
  end
end
