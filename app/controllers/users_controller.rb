class UsersController < ApplicationController
  def show

    users = []

    User.all.each do |user|
      unless @current_user.id == user.id
        users.push({ username: user.username, id: user.id })
      end
    end

    render json: users
  end
end
