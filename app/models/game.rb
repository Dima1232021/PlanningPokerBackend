# frozen_string_literal: true

class Game < ApplicationRecord
  has_many :stories, dependent: :destroy

  has_many :invitation_to_the_games, dependent: :destroy
  has_many :users, through: :invitation_to_the_games

  validates :name_game, presence: true, length: { minimum: 5, maximum: 50 }
end
