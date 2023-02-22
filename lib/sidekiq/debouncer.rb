# frozen_string_literal: true

require_relative "debouncer/version"
require_relative "debouncer/errors"
require_relative "debouncer/middleware/client"
require_relative "debouncer/middleware/server"

module Sidekiq
  module Debouncer
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
