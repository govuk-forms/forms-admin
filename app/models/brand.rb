class Brand < ApplicationRecord
  validates :slug, presence: true, uniqueness: true
  validates :name, presence: true
end
