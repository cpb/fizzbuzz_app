class CascadeWorkbookSessionFks < ActiveRecord::Migration[8.1]
  def change
    remove_foreign_key :biased_thoughts, :workbook_sessions
    add_foreign_key :biased_thoughts, :workbook_sessions, on_delete: :cascade

    remove_foreign_key :thinking_trap_evaluations, :workbook_sessions
    add_foreign_key :thinking_trap_evaluations, :workbook_sessions, on_delete: :cascade
  end
end
