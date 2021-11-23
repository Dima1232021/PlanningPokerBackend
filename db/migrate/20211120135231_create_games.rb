class CreateGames < ActiveRecord::Migration[6.1]
  def change
    create_table :games do |t|
      t.string :name
      t.integer :driving
      t.json :joined, array: true, default: []

      t.timestamps
    end
  end
end
