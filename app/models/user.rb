class User < ApplicationRecord
  has_many :answers, dependent: :destroy
  has_many :stories, through: :answers

  has_many :invitation_to_the_games, dependent: :destroy
  has_many :games, through: :invitation_to_the_games

  has_secure_password
  validates :password, length: { minimum: 6, maximum: 16 }, on: :create
  validates :username,
            presence: true,
            uniqueness: {
              case_sensitive: false
            },
            length: {
              minimum: 5,
              maximum: 50
            }

  validates :email,
            presence: true,
            format: {
              with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i
            },
            uniqueness: {
              case_sensitive: false
            }
end
