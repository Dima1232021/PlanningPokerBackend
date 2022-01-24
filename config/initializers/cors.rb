Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins 'https://planning-poker-frontend-atom.herokuapp.com'

    resource '*',
             headers: :any,
             methods: %i[get post put patch delete options head],
             credentials: true
  end
end
