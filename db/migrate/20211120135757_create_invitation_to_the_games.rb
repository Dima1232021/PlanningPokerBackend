class CreateInvitationToTheGames < ActiveRecord::Migration[6.1]
  def change
    create_table :invitation_to_the_games do |t|
      t.belongs_to :user, null: false, foreign_key: true
      t.belongs_to :game, null: false, foreign_key: true
      t.boolean :invitation, default: false

      t.timestamps
    end
  end
end
