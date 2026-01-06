# frozen_string_literal: true

module Sidekiq
  module Debouncer
    class Job
      attr_reader :key, :score

      def initialize(key, score)
        @key = key
        @score = Float(score)
      end

      def at
        Time.at(score).utc
      end

      def args
        item["args"]
      end

      def queue
        item["queue"]
      end

      def klass
        key.split("/")[2]
      end

      alias_method :display_class, :klass

      def item
        @_item ||= begin
          job_args = Sidekiq.redis { |conn| conn.call("ZRANGE", key, "-inf", "+inf", "BYSCORE") }
          JobBuilder.build(job_args, key)
        end
      end
    end
  end
end
