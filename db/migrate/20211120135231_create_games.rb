class CreateGames < ActiveRecord::Migration[6.1]
  def change
    create_table :games do |t|
      t.string :name_game
      t.integer :driving_id
      t.json :driving, null: false, default: '{}'
      t.integer :users_joined, array: true, default: []
      t.json :players, array: true, default: []

      t.timestamps
    end
  end
end
