# frozen_string_literal: true

require "base64"

module Sidekiq
  module Debouncer
    module WebExtension
      module Helpers
        def get_route_param(key)
          if Gem::Version.new(Sidekiq::VERSION) >= Gem::Version.new("8.0.0")
            route_params(key)
          else
            route_params[key]
          end
        end

        def get_url_param(key)
          if Gem::Version.new(Sidekiq::VERSION) >= Gem::Version.new("8.0.0")
            url_params(key)
          else
            params[key]
          end
        end
      end

      def self.registered(app)
        locales = if Gem::Version.new(Sidekiq::VERSION) >= Gem::Version.new("8.0.0")
                    Sidekiq::Web.configure.locales
                  else
                    app.settings.locales
                  end

        locales << File.join(File.expand_path("..", __FILE__), "locales")

        app.helpers(Helpers)

        app.get "/debounces" do
          view_path = File.join(File.expand_path("..", __FILE__), "views")

          @count = (get_url_param("count") || 25).to_i
          (@current_page, @total_size, @debounces) = page("debouncer", get_url_param("page"), @count)
          @debounces = @debounces.map { |key, score| Sidekiq::Debouncer::Job.new(key, score) }

          render(:erb, File.read(File.join(view_path, "index.html.erb")))
        end

        app.get "/debounces/:key" do
          view_path = File.join(File.expand_path("..", __FILE__), "views")

          @job = Sidekiq::Debouncer::Set.new.fetch_by_key(Base64.urlsafe_decode64(get_route_param(:key)))

          render(:erb, File.read(File.join(view_path, "show.html.erb")))
        end
      end
    end
  end
end
