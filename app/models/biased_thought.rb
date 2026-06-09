class BiasedThought < ApplicationRecord
  belongs_to :workbook_session

  validates :thought, presence: true, on: :update
end
