class RemoveCbtWorkbookTables < ActiveRecord::Migration[8.1]
  def up
    drop_table :thinking_trap_evaluations
    drop_table :biased_thoughts
    drop_table :workbook_sessions
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
