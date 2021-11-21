class GameController < ApplicationController
  include CurrentUserConcern

  def index
    idCurrentUser = @current_user.id

    users = []

    User.all.each do |user|
      unless idCurrentUser == user.id
        users.push({ username: user.username, id: user.id })
      end
    end

    render json: users
  end
end
