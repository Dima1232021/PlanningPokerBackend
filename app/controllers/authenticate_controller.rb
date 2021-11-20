class AuthenticateController < ApplicationController
  include CurrentUserConcern

  def create
    username = params['user']['username']
    email = params['user']['email']
    password = params['user']['password']
    password_confirmation = params['user']['password_confirmation']

    user =
      User.create!(
        username: username,
        email: email,
        password: password,
        password_confirmation: password_confirmation,
      )

    numberOfUsers = User.count
    ActionCable.server.broadcast 'show_users_cannel', numberOfUsers
    session[:user_id] = user.id
    render json: { status: :created, user: user, logged_in: true }
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.to_s, status: 400 }
  end

  def login
    email = params['user']['email']
    password = params['user']['password']

    if email.length === 0 || password.length === 0
      return(
        render json: {
                 status: 400,
                 message: 'Email or Password cannot be blank',
               }
      )
    end

    user = User.find_by(email: email).try(:authenticate, password)

    if user
      session[:user_id] = user.id
      render json: { status: :created, logged_in: true, user: user }
    else
      render json: {
               status: 400,
               message: 'Validation failed: invalid login or password',
             }
    end
  end

  def logged_in
    if @current_user
      render json: { logged_in: true, user: @current_user }
    else
      render json: { logged_in: false }
    end
  end

  def logout
    reset_session
    render json: { status: 200, logged_out: true }
  end
end
