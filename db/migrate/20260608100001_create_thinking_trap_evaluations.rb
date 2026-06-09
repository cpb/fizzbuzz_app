class CreateThinkingTrapEvaluations < ActiveRecord::Migration[8.0]
  def change
    create_table :thinking_trap_evaluations do |t|
      t.references :workbook_session, null: false, foreign_key: true
      t.text :submitted_traps
      t.string :outcome
      t.text :feedback_text

      t.timestamps
    end
  end
end
