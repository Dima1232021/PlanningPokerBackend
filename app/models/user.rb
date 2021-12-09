class User < ApplicationRecord
  has_many :answers, dependent: :destroy
  has_many :stories, through: :answers

  has_many :invitation_to_the_games, dependent: :destroy
  has_many :games, through: :invitation_to_the_games

  has_secure_password

  validates :username, length: { minimum: 5 }
  validates_uniqueness_of :username

  validates_format_of :email,
                      with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i
  validates_uniqueness_of :email
end
