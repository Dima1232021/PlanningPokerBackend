# frozen_string_literal: true

require_relative 'boot'

require 'rails'
# Pick the frameworks you want:
require 'active_model/railtie'
require 'active_job/railtie'
require 'active_record/railtie'
require 'active_storage/engine'
require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'action_mailbox/engine'
require 'action_text/engine'
require 'action_view/railtie'
require 'action_cable/engine'

Bundler.require(*Rails.groups)

module Backend
  class Application < Rails::Application
    config.load_defaults 6.1

    config.api_only = true

    config.middleware.use ActionDispatch::Cookies
    config.middleware.use ActionDispatch::Session::CookieStore,
                          key: '_authentication_app',
                          path: '/',
                          expire_after: 20.years,
                          same_site: :None,
                          secure: true

    # config.middleware.insert_after(
    #   ActionDispatch::Cookies,
    #   ActionDispatch::Session::CookieStore,
    #   key: '_authentication_app',
    #   path: '/',
    #   same_site: :None,
    #   secure: true,
    # )

    config.hosts << 'devserver.test'
  end
end
