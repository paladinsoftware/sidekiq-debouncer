# frozen_string_literal: true

module Sidekiq
  module Debouncer
    class Job
      include Sidekiq::JobUtil

      attr_reader :key, :score

      def initialize(key, score)
        @key = key
        @score = Float(score)
      end

      def at
        Time.at(score).utc
      end

      def args
        @_args ||= Sidekiq.redis { |conn| conn.call("ZRANGE", key, "-inf", "+inf", "BYSCORE") }
          .map { |elem| Sidekiq.load_json(elem.split("-", 2)[1]) }
      end

      def queue
        normalized["queue"]
      end

      def klass
        key.split("/")[2]
      end

      alias_method :display_class, :klass

      private

      def normalized
        @_normalized ||= normalize_item({"args" => args, "class" => Object.const_get(klass), "debounce_key" => key})
      end
    end
  end
end
