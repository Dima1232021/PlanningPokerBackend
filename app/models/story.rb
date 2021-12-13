class Story < ApplicationRecord
  has_many :answers, dependent: :destroy
  has_many :users, through: :answers

  belongs_to :game

  validates :body, presence: true, length: { minimum: 10, maximum: 1000 }
end
