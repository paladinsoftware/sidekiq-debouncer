# frozen_string_literal: true

module Sidekiq
  module Debouncer
    class Set < Sidekiq::JobSet
      def initialize
        super Sidekiq::Debouncer::SET
      end

      def fetch_by_key(key)
        score = Sidekiq.redis { |conn| conn.zscore(Sidekiq::Debouncer::SET, key) }
        Job.new(key, score)
      end
    end
  end
end
