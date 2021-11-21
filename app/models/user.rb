class User < ApplicationRecord
  include PgSearch
  pg_search_scope :search_everywhere, against: [:username]

  has_many :invitation_to_the_games, dependent: :destroy
  has_many :games, through: :invitation_to_the_games

  has_secure_password

  validates :username, length: { minimum: 5 }
  validates_uniqueness_of :username

  validates_format_of :email,
                      with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i
  validates_uniqueness_of :email
end
