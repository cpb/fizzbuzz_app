class CreateBiasedThoughts < ActiveRecord::Migration[8.1]
  def change
    unless table_exists?(:biased_thoughts)
      create_table :biased_thoughts do |t|
        t.datetime :created_at, null: false
        t.text :evidence_against
        t.text :evidence_for
        t.integer :position
        t.integer :post_believability
        t.integer :pre_believability
        t.text :rational_response
        t.text :thought
        t.datetime :updated_at, null: false
        t.integer :workbook_session_id, null: false
      end
      add_index :biased_thoughts, :workbook_session_id, name: "index_biased_thoughts_on_workbook_session_id"
      add_foreign_key :biased_thoughts, :workbook_sessions
    end
  end
end
