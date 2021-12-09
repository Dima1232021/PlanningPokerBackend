class Story < ApplicationRecord
  has_many :answers, dependent: :destroy
  has_many :users, through: :answers

  belongs_to :game
end
