Rails.application.routes.draw do
  post '/authenticate/login', to: 'authenticate#login'
  post '/authenticate/create', to: 'authenticate#create'
  post '/game/create', to: 'game#create'
  post '/game/join_the_game', to: 'game#joinTheGame'
  post '/game/leave_the_game', to: 'game#leaveTheGame'

  get '/authenticate/logged_in', to: 'authenticate#logged_in'
  get '/users/show', to: 'users#index'
  get '/game/your_games', to: 'game#yourGames'
  get '/game/invited_games', to: 'game#invitedGames'
  get '/game/search_game_you_have_joined', to: 'game#searchGameYouHaveJoined'

  delete '/authenticate/logout', to: 'authenticate#logout'
  delete '/game/delete_game', to: 'game#deleteGame'

  mount ActionCable.server => '/cable'
end
