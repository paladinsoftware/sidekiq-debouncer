# frozen_string_literal: true

module Sidekiq
  module Debouncer
    class Set < Sidekiq::JobSet
      def initialize
        super Sidekiq::Debouncer::Enq::SET
      end
    end
  end
end
