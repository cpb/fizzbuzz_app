class Link < ApplicationRecord
  validates :title, presence: true
  validates :url, presence: true

  broadcasts_to ->(_link) { :links }
end
