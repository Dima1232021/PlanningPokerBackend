# frozen_string_literal: true

class ShowingGameRequestsChannel < ApplicationCable::Channel
  def subscribed
    user = User.find(params[:user])
    stream_for user
  end

  def unsubscribed; end
end
