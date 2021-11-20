class GameController < ApplicationController
  include CurrentUserConcern

  def index
    users = User.all
    changedUsers = users.map { |user| { username: user.username, id: user.id } }

    render json: changedUsers
end
