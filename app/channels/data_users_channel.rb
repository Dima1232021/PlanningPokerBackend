class DataUsersChannel < ApplicationCable::Channel
  def subscribed
    gameId = params['gameId']
    stream_from "data_users_channel_#{gameId}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
