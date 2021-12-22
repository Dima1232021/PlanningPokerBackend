# frozen_string_literal: true

class DeleteGameChannel < ApplicationCable::Channel
  def subscribed
    user_id = params['userid']
    stream_from "delete_game_channel_#{user_id}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
