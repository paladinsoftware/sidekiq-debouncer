# frozen_string_literal: true

require "base64"

module Sidekiq
  module Debouncer
    module WebExtension
      def self.registered(app)
        app.settings.locales << File.join(File.expand_path("..", __FILE__), "locales")

        app.get "/debounces" do
          view_path = File.join(File.expand_path("..", __FILE__), "views")

          @count = (params["count"] || 25).to_i
          (@current_page, @total_size, @debounces) = page("debouncer", params["page"], @count)
          @debounces = @debounces.map { |key, score| Sidekiq::Debouncer::Job.new(key, score) }

          render(:erb, File.read(File.join(view_path, "index.html.erb")))
        end

        app.get "/debounces/:key" do
          view_path = File.join(File.expand_path("..", __FILE__), "views")

          @job = Sidekiq::Debouncer::Set.new.fetch_by_key(Base64.urlsafe_decode64(route_params[:key]))

          render(:erb, File.read(File.join(view_path, "show.html.erb")))
        end
      end
    end
  end
end
