class AddGistIdToLinks < ActiveRecord::Migration[8.1]
  def change
    add_column :links, :gist_id, :string
  end
end
