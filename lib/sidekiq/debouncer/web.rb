# frozen_string_literal: true

if defined?(Sidekiq::Web)
  require "sidekiq/debouncer/web_extension"

  Sidekiq::Web.register Sidekiq::Debouncer::WebExtension
  Sidekiq::Web.tabs["Debounces"] = "debounces"
end
