class AddWorkbookBiasedThoughts < ActiveRecord::Migration[8.1]
  def change
    add_column :biased_thoughts, :position, :integer unless column_exists?(:biased_thoughts, :position)

    add_column :workbook_sessions, :tipp_strategy, :string
    add_column :workbook_sessions, :review_direction, :string
    add_column :workbook_sessions, :primary_thought_id, :integer

    # Rename the stale json column to avoid conflict with has_many :biased_thoughts
    rename_column :workbook_sessions, :biased_thoughts, :biased_thoughts_json
  end
end
