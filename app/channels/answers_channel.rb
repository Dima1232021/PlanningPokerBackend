# frozen_string_literal: true

class AnswersChannel < ApplicationCable::Channel
  def subscribed
    game_id = params['game_id']
    stream_from "answers_channel_#{game_id}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
