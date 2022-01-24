class DeleteGameChannel < ApplicationCable::Channel
  def subscribed
    userId = params['userId']
    stream_from "delete_game_channel_#{userId}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
