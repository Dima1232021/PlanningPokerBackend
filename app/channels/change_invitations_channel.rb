class ChangeInvitationsChannel < ApplicationCable::Channel
  def subscribed
    game_id = params['game_id']
    stream_from "change_invitations_channel_#{game_id}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
