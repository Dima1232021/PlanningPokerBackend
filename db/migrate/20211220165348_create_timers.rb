class CreateTimers < ActiveRecord::Migration[6.1]
  def change
    create_table :timers do |t|
      t.boolean :timer, default: true
      t.integer :timer_time
      t.belongs_to :game, null: false, foreign_key: true

      t.timestamps
    end
  end
end
