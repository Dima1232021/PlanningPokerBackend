class DeleteInvitedChannel < ApplicationCable::Channel
  def subscribed
    userid = params['userid']
    stream_from "delete_invited_channel_#{userid}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
