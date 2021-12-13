# frozen_string_literal: true

class UsersController < ApplicationController
  def show
    users = []

    User.all.each do |user|
      users.push({ username: user.username, id: user.id }) unless @current_user.id == user.id
    end

    render json: users
  end
end
