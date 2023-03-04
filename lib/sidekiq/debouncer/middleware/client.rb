# frozen_string_literal: true

require "digest/sha1"

module Sidekiq
  module Debouncer
    module Middleware
      # Middleware used to debounce jobs. If a job has a debounce option it skips normal sidekiq flow and debounces
      # job using lua script (thanks to that it's process safe). Script merges new job with existing one and creates
      # debounce key in redis with a reference to the job placed in schedule set. Reference is used to remove existing
      # job from schedule set when another debounce occurs.
      class Client
        include Sidekiq::ClientMiddleware

        LUA_DEBOUNCE = File.read(File.expand_path("../../lua/debounce.lua", __FILE__))
        LUA_DEBOUNCE_SHA = Digest::SHA1.hexdigest(LUA_DEBOUNCE)
        REDIS_ERROR_CLASS = defined?(RedisClient::CommandError) ? RedisClient::CommandError : Redis::CommandError

        def initialize(options = {})
          @debounce_key_ttl = options.fetch(:ttl, 60 * 60 * 24) # 24 hours by default
        end

        def call(worker_class, job, _queue, _redis_pool)
          klass = worker_class.is_a?(String) ? Object.const_get(worker_class) : worker_class

          yield # call the rest of middleware stack
          # skip if debounce options not set or client middleware is included in server
          return job if !klass.get_sidekiq_options["debounce"] || job["debounce_key"]

          debounce(klass, job)

          # prevent normal sidekiq flow
          false
        end

        private

        def debounce(klass, job)
          raise NotSupportedError, "perform_at is not supported with debounce" if job.key?("at")

          options = debounce_options(klass)
          key = debounce_key(klass, job, options)
          time = (options[:time].to_f + Time.now.to_f).to_s

          job["debounce_key"] = key
          job["args"] = [job["args"]]
          job.delete("debounce")

          redis do |connection|
            redis_debounce(connection, keys: ["schedule", key], argv: [Sidekiq.dump_json(job), time, @debounce_key_ttl])
          end
        end

        def debounce_key(klass, job, options)
          method = options[:by]
          result = method.is_a?(Symbol) ? klass.send(method, job["args"]) : method.call(job["args"])
          "debounce/#{klass.name}/#{result}"
        end

        def debounce_options(klass)
          options = klass.get_sidekiq_options["debounce"].transform_keys(&:to_sym)

          raise MissingArgumentError, "'by' attribute not provided" unless options[:by]
          raise MissingArgumentError, "'time' attribute not provided" unless options[:time]

          options
        end

        def redis_debounce(connection, keys:, argv:)
          retryable = true
          begin
            connection.call("EVALSHA", LUA_DEBOUNCE_SHA, keys.size, *keys, *argv)
          rescue REDIS_ERROR_CLASS => e
            raise if !e.message.start_with?("NOSCRIPT") || !retryable

            # upload script to redis cache and retry
            connection.call("SCRIPT", "LOAD", LUA_DEBOUNCE)
            retryable = false
            retry
          end
        end
      end
    end
  end
end
