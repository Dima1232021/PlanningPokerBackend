class Answer < ApplicationRecord
  belongs_to :story
  belongs_to :user
end
