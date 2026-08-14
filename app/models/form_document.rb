class FormDocument < ApplicationRecord
  belongs_to :form

  validates :tag, presence: true
  validates :language, presence: true, inclusion: { in: %w[en cy] }

  def self.latest_live_or_archived(form_id:, language:)
    FormDocument.where(form_id: form_id, language: language)
                .where.not(version: nil)
                .order(version: :desc)
                .first
  end
end
