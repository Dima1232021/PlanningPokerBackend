class GameController < ApplicationController
  include CurrentUserConcern

  def index
    idCurrentUser = @current_user.id

    # users = User.all.map { |user| { username: user.username, id: user.id } }

    users = User.all.select { |user| idCurrentUser != user.id }
    render json: users
  end
end
