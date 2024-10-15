# frozen_string_literal: true

require "sidekiq/scheduled"

module Sidekiq
  module Debouncer
    class Poller < ::Sidekiq::Scheduled::Poller
      def initialize(config)
        super
        @enq = Sidekiq::Debouncer::Enq.new(config)
      end
    end
  end
end
