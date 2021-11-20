class GameController < ApplicationController
  include CurrentUserConcern

  def index
    users = User.all.map { |user| { username: user.username, id: user.id } }

    render json: users
  end
end
