class CreateGists < ActiveRecord::Migration[8.1]
  def change
    create_table :gists do |t|
      t.string :url
      t.datetime :published_at

      t.timestamps
    end
  end
end
