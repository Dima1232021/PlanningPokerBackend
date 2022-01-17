# frozen_string_literal: true

Rails.application.routes.draw do
  post '/authenticate/login', to: 'authenticate#login'
  post '/authenticate/create', to: 'authenticate#create'
  post '/games/createGame', to: 'games#createGame'
  post '/games/delete_game', to: 'games#deleteGame'

  post '/game/join_the_game', to: 'game#joinTheGame'
  post '/game/leave_the_game', to: 'game#leaveTheGame'
  post '/game/start_a_poll', to: 'game#startAPoll'
  post '/game/flip_card', to: 'game#flipCard'
  post '/game/reset_cards', to: 'game#resetCards'
  post '/game/player_settings', to: 'game#playerSettings'
  post '/game/change_card_flip_settings', to: 'game#changeCardFlipSettings'
  post '/game/give_an_answer', to: 'game#giveAnAnswer'
  post '/game/add_history', to: 'game#addHistory'
  post '/game/edit_history', to: 'game#editHistory'
  post '/game/change_host_settings', to: 'game#changeHostSettings'

  get '/authenticate/logged_in', to: 'authenticate#logged_in'

  get '/game/find_game_you_have_joined', to: 'game#findGameYouHaveJoined'
  get '/authenticate/logout', to: 'authenticate#logout'
  get '/games', to: 'games#games'

  # delete '/game/delete_invited', to: 'game#deleteInvited'
  # delete '/game/delete_history', to: 'game#deleteHistory'

  mount ActionCable.server => '/cable'
end
