# frozen_string_literal: true

class CreateGames < ActiveRecord::Migration[6.1]
  def change
    create_table :games do |t|
      t.string :name_game
      t.json :driving, null: false, default: {}
      t.json :users_joined, array: true, default: []
      t.json :players, array: true, default: []
      t.json :selected_story, null: false, default: {}
      t.integer :id_players_responded, array: true, default: []

      t.timestamps
    end
  end
end
