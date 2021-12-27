# frozen_string_literal: true

class CreateAnswers < ActiveRecord::Migration[6.1]
  def change
    create_table :answers do |t|
      t.text :body
      t.belongs_to :story, null: false, foreign_key: true
      t.belongs_to :user, null: false, foreign_key: true
      t.string :user_name

      t.timestamps
    end
  end
end
