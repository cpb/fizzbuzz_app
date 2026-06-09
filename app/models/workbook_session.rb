class WorkbookSession < ApplicationRecord
  validates :current_step, presence: true
end
