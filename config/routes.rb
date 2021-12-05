Rails.application.routes.draw do
  post '/authenticate/login', to: 'authenticate#login'
  post '/authenticate/create', to: 'authenticate#create'
  post '/game/create', to: 'create_game#create'
  post '/game/join_the_game', to: 'create_game#joinTheGame'
  post '/game/leave_the_game', to: 'create_game#leaveTheGame'

  get '/authenticate/logged_in', to: 'authenticate#logged_in'
  get '/users/show', to: 'users#index'
  get '/game/your_games', to: 'create_game#yourGames'
  get '/game/invited_games', to: 'create_game#invitedGames'
  get '/game/search_game_you_have_joined',
      to: 'create_game#searchGameYouHaveJoined'

  delete '/authenticate/logout', to: 'authenticate#logout'
  delete '/game/delete_game', to: 'create_game#deleteGame'
  delete '/game/delete_invited', to: 'create_game#deleteInvited'

  mount ActionCable.server => '/cable'
end
