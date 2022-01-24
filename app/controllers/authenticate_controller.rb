# frozen_string_literal: true

class AuthenticateController < ApplicationController
  def create
    username = params['username']
    email = params['email']
    password = params['password']
    password_confirmation = params['passwordConf']

    user =
      User.create!(
        username: username,
        email: email,
        password: password,
        password_confirmation: password_confirmation,
      )

    session[:user_id] = user.id
    render json: { userId: user.id, username: user.username, isAuth: true }
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.to_s }
  end

  def login
    email = params['email']
    password = params['password']
    user = User.find_by!(email: email).try(:authenticate, password)

    session[:user_id] = user.id
    render json: { userId: user.id, username: user.username, isAuth: true }
  rescue StandardError
    render json: { error: 'Validation failed: invalid login or password' }
  end

  def logged_in
    if @current_user
      render json: { isAuth: true, userId: @current_user.id, username: @current_user.username }
    else
      render json: { isAuth: false }
    end
  end

  def logout
    reset_session
    render json: { logged_out: true }
  end
end
