class ChangePlayersOnlineChannel < ApplicationCable::Channel
  def subscribed
    gameId = params['gameId']
    stream_from "change_players_online_channel_#{gameId}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
