class CreateStories < ActiveRecord::Migration[6.1]
  def change
    create_table :stories do |t|
      t.text :body, null: false
      t.belongs_to :game, null: false, foreign_key: true

      t.timestamps
    end
  end
end
