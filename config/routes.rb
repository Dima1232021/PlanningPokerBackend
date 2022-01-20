# frozen_string_literal: true

Rails.application.routes.draw do
  # |||||||||||||||||---POST---|||||||||||||||||
  post '/authenticate/login', to: 'authenticate#login'
  post '/authenticate/create', to: 'authenticate#create'

  post '/games/createGame', to: 'games#createGame'
  post '/games/delete_game', to: 'games#deleteGame'

  post '/game/join_the_game', to: 'game#joinTheGame'
  post '/game/add_history', to: 'game#addHistory'
  post '/game/edit_history', to: 'game#editHistory'
  post '/game/remove_story', to: 'game#removeStory'
  post '/game/delete_invited', to: 'game#deleteInvited'
  post '/game/change_driving_Setings', to: 'game#changeDrivingSetings'
  post '/game/change_game_settings', to: 'game#changeGameSettings'
  post '/game/start_poll', to: 'game#startPoll'
  post '/game/flip_card', to: 'game#flipCard'
  post '/game/reset_cards', to: 'game#resetCards'
  post '/game/give_an_answer', to: 'game#giveAnAnswer'

  # |||||||||||||||||---GET---|||||||||||||||||
  get '/authenticate/logged_in', to: 'authenticate#logged_in'
  get '/authenticate/logout', to: 'authenticate#logout'

  get '/game/leave_the_game', to: 'game#leaveTheGame'
  get '/game/find_game_you_have_joined', to: 'game#findGameYouHaveJoined'

  get '/games', to: 'games#games'

  mount ActionCable.server => '/cable'
end
