Rails.application.routes.draw do
  post '/authenticate/login', to: 'authenticate#login'
  post '/authenticate/create', to: 'authenticate#create'
  post '/game/create', to: 'create_game#create'
  post '/game/join_the_game', to: 'create_game#joinTheGame'
  post '/game/leave_the_game', to: 'create_game#leaveTheGame'
  post '/game/start_a_poll', to: 'create_game#startAPoll'
  post '/game/finish_a_poll', to: 'create_game#finishAPoll'
  post '/game/give_an_answer', to: 'create_game#giveAnAnswer'
  post '/game/add_history', to: 'create_game#addHistory'
  post '/game/edit_history', to: 'create_game#editHistory'

  get '/authenticate/logged_in', to: 'authenticate#logged_in'
  get '/users/show', to: 'users#show'
  get '/game/your_games', to: 'create_game#yourGames'
  get '/game/invited_games', to: 'create_game#invitedGames'
  get '/game/search_game_you_have_joined',
      to: 'create_game#searchGameYouHaveJoined'

  delete '/authenticate/logout', to: 'authenticate#logout'
  delete '/game/delete_game', to: 'create_game#deleteGame'
  delete '/game/delete_invited', to: 'create_game#deleteInvited'
  delete '/game/delete_history', to: 'create_game#deleteHistory'

  mount ActionCable.server => '/cable'
end
