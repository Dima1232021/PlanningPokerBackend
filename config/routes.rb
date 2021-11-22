Rails.application.routes.draw do
  post '/authenticate/login', to: 'authenticate#login'
  post '/authenticate/create', to: 'authenticate#create'
  post '/game/create', to: 'game#create'

  get '/authenticate/logged_in', to: 'authenticate#logged_in'
  get '/users/show', to: 'users#index'
  get '/game/your_games', to: 'game#yourGames'

  delete '/authenticate/logout', to: 'authenticate#logout'

  mount ActionCable.server => '/cable'
end
