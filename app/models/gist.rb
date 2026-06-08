class Gist < ApplicationRecord
  validates :url, presence: true

  def self.latest
    order(published_at: :desc).first
  end
end
