class SetingsGameChannel < ApplicationCable::Channel
  def subscribed
    gameId = params['gameId']
    stream_from "setings_game_channel_#{gameId}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
