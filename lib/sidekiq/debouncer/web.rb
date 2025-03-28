# frozen_string_literal: true

if defined?(Sidekiq::Web)
  require "sidekiq/debouncer/web_extension"

  if Gem::Version.new(Sidekiq::VERSION) >= Gem::Version.new("8.0.0")
    Sidekiq::Web.configure do |config|
      config.register(
        Sidekiq::Debouncer::WebExtension,
        name: "debounces",
        tab: "Debounces",
        index: "debounces"
      )
    end
  elsif Gem::Version.new(Sidekiq::VERSION) >= Gem::Version.new("7.3.0")
    Sidekiq::Web.register(
      Sidekiq::Debouncer::WebExtension,
      name: "debounces",
      tab: "Debounces",
      index: "debounces"
    )
  else
    Sidekiq::Web.register Sidekiq::Debouncer::WebExtension
    Sidekiq::Web.tabs["Debounces"] = "debounces"
  end
end
