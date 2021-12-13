# frozen_string_literal: true

class ShowUsersChannel < ApplicationCable::Channel
  def subscribed
    stream_from 'show_users_cannel'
  end

  def unsubscribed; end
end
