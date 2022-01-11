# frozen_string_literal: true

class AnswersChannel < ApplicationCable::Channel
  def subscribed
    gameId = params['gameId']
    stream_from "answers_channel_#{gameId}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
