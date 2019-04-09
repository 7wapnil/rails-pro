class AddUniqueIndexesToCompetitors < ActiveRecord::Migration[5.2]
  def change
    add_index :competitors, :external_id, unique: true
    add_index :players, :external_id, unique: true
  end
end
