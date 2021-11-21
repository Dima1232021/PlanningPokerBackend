class ApplicationController < ActionController::API
  include ActionController::Cookies
  include CurrentUserConcern
end
