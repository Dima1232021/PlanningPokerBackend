# frozen_string_literal: true

class InvitationToTheGame < ApplicationRecord
  belongs_to :user
  belongs_to :game
end
