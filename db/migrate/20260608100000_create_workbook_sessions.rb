class CreateWorkbookSessions < ActiveRecord::Migration[8.0]
  def change
    create_table :workbook_sessions do |t|
      t.string :current_step
      t.integer :suds_initial
      t.integer :suds_post_tipp
      t.integer :suds_post_restructuring
      t.text :situation_description
      t.text :biased_thoughts
      t.integer :pre_believability
      t.integer :post_believability
      t.text :selected_thinking_traps
      t.text :evidence_for
      t.text :evidence_against
      t.text :rational_response
      t.integer :rational_believability
      t.text :dear_plan
      t.text :give_plan

      t.timestamps
    end
  end
end
