class InvitationChannel < ApplicationCable::Channel
  def subscribed
    userId = params['userId']
    stream_from "invitation_channel_#{userId}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
