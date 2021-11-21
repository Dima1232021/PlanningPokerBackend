class UsersController < ApplicationController
  include CurrentUserConcern

  def index
    idCurrentUser = @current_user.id

    # users = User.all.map { |user| { username: user.username, id: user.id } }

    #   users = User.all.select { |user| idCurrentUser != user.id }
    # users =
    #   User.all.each { |user| mm.push({ username: user.username, id: user.id }) }

    render json: { name: 'adsfasd' }
  end
end
