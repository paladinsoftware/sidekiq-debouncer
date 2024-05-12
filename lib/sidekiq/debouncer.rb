# frozen_string_literal: true

require "sidekiq/debouncer/version"
require "sidekiq/debouncer/errors"
require "sidekiq/debouncer/lua_commands"
require "sidekiq/debouncer/middleware/client"
require "sidekiq/debouncer/middleware/server"
require "sidekiq/debouncer/job"
require "sidekiq/debouncer/set"

module Sidekiq
  module Debouncer
    SET = "debouncer"

    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def debounce(...)
        warn "WARNING: debounce method is deprecated, use perform_async instead"
        perform_async(...)
      end
    end
  end
end

Sidekiq.configure_server do
  require "sidekiq/debouncer/enq"
  require "sidekiq/debouncer/poller"
  require "sidekiq/debouncer/launcher"
end
