# frozen_string_literal: true

Rails.application.routes.draw do
  post '/authenticate/login', to: 'authenticate#login'
  post '/authenticate/create', to: 'authenticate#create'
  post '/game/create', to: 'game#create'
  post '/game/join_the_game', to: 'game#joinTheGame'
  post '/game/leave_the_game', to: 'game#leaveTheGame'
  post '/game/start_a_poll', to: 'game#startAPoll'
  post '/game/flip_card', to: 'game#flipCard'
  post '/game/reset_cards', to: 'game#resetCards'
  post '/game/player_settings', to: 'game#playerSettings'

  post '/game/give_an_answer', to: 'game#giveAnAnswer'
  post '/game/add_history', to: 'game#addHistory'
  post '/game/edit_history', to: 'game#editHistory'
  post '/game/change_host_settings', to: 'game#changeHostSettings'

  get '/authenticate/logged_in', to: 'authenticate#logged_in'
  get '/users/show', to: 'users#show'
  get '/game/your_games', to: 'game#yourGames'
  get '/game/invited_games', to: 'game#invitedGames'
  get '/game/search_game_you_have_joined', to: 'game#searchGameYouHaveJoined'

  delete '/authenticate/logout', to: 'authenticate#logout'
  delete '/game/delete_game', to: 'game#deleteGame'
  delete '/game/delete_invited', to: 'game#deleteInvited'
  delete '/game/delete_history', to: 'game#deleteHistory'

  mount ActionCable.server => '/cable'
end
