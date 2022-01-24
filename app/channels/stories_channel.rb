# frozen_string_literal: true

class StoriesChannel < ApplicationCable::Channel
  def subscribed
    game_id = params['game_id']
    stream_from "stories_channel_#{game_id}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
