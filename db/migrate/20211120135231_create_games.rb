class CreateGames < ActiveRecord::Migration[6.1]
  def change
    create_table :games do |t|
      t.string :name
      t.string :driving
      t.string 'tags', array: true
      
      t.timestamps
    end
  end
end
