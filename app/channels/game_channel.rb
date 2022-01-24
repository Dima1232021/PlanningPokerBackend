# frozen_string_literal: true

class GameChannel < ApplicationCable::Channel
  def subscribed
    gameId = params['gameId']
    stream_from "game_channel_#{gameId}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
