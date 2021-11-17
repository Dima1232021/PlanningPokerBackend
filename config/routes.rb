Rails.application.routes.draw do
  post '/authenticate/login', to: 'authenticate#login'
  post '/authenticate/create', to: 'authenticate#create'
  get '/authenticate/logged_in', to: 'authenticate#logged_in'
  delete '/authenticate/logout', to: 'authenticate#logout'
end
