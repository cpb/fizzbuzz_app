class ThinkingTrapEvaluation < ApplicationRecord
  belongs_to :workbook_session
  validates :outcome, presence: true
end
