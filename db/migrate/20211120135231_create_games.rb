# frozen_string_literal: true

class CreateGames < ActiveRecord::Migration[6.1]
  def change
    create_table :games do |t|
      t.string :name_game
      t.json :driving, null: false, default: {}
      t.json :history_poll, null: false, default: {}
      t.integer :id_players_answers, array: true, default: []
      t.boolean :poll, default: false

      t.timestamps
    end
  end
end
