# frozen_string_literal: true

module Sidekiq
  module Debouncer
    module Launcher
      def initialize(config, **kwargs)
        @debounce_poller = Sidekiq::Debouncer::Poller.new(config)
        super
      end

      def run
        super
        @debounce_poller.start
      end

      def quiet
        super
        @debounce_poller.terminate
      end

      def stop
        @debounce_poller.terminate
        super
      end
    end
  end
end

Sidekiq.configure_server do
  require "sidekiq/launcher"

  ::Sidekiq::Launcher.prepend(Sidekiq::Debouncer::Launcher)
end
