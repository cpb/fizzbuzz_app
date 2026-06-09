class CreateSurveyResponses < ActiveRecord::Migration[8.1]
  def change
    create_table :survey_responses do |t|
      t.text    :location
      t.string  :role,                  null: false
      t.boolean :writes_ruby,           null: false
      t.string  :paid_to_write_ruby,    null: false
      t.string  :years_of_experience,   null: false
      t.string  :prior_experience,      null: false
      t.string  :team_ai_adoption,      null: false
      t.text    :ai_tools,              null: false, default: "[]"
      t.integer :likert_overhyped
      t.integer :likert_frustrated
      t.integer :likert_limit_to_boilerplate
      t.integer :likert_anxious
      t.integer :likert_made_peace
      t.integer :likert_more_capable
      t.datetime :submitted_at,         null: false
      t.timestamps
    end
    add_index :survey_responses, :role
    add_index :survey_responses, :submitted_at
  end
end
