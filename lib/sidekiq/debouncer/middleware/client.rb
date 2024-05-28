# frozen_string_literal: true

require "securerandom"

module Sidekiq
  module Debouncer
    module Middleware
      # Middleware used to debounce jobs. If a job has a debounce option it skips normal sidekiq flow and debounces
      # job using lua script (thanks to that it's process safe). Script merges new job with existing one and creates
      # debounce key in redis with a reference to the job placed in schedule set. Reference is used to remove existing
      # job from schedule set when another debounce occurs.
      class Client
        include Sidekiq::ClientMiddleware
        extend Sidekiq::Debouncer::LuaCommands

        LUA_DEBOUNCE = File.read(File.expand_path("../../lua/debounce.lua", __FILE__))

        define_lua_command(:redis_debounce, LUA_DEBOUNCE)

        def initialize(options = {})
          @debounce_key_ttl = options.fetch(:ttl, 60 * 60 * 24) # 24 hours by default
        end

        def call(worker_class, job, _queue, _redis_pool)
          klass = worker_class.is_a?(String) ? Object.const_get(worker_class) : worker_class

          yield # call the rest of middleware stack
          # skip if debounce options not set or client middleware is included in server
          return job if !klass.get_sidekiq_options["debounce"] || job["debounce_key"]

          debounce(klass, job)
        end

        private

        def debounce(klass, job)
          raise NotSupportedError, "perform_at is not supported with debounce" if job.key?("at")

          options = debounce_options(klass)
          key = debounce_key(klass, job, options)
          time = (options[:time].to_f + Time.now.to_f).to_s

          return job.merge("args" => [job["args"]], "debounce_key" => key) if testing?

          args_stringified = "#{SecureRandom.hex(12)}-#{Sidekiq.dump_json(job["args"])}"

          redis do |connection|
            redis_debounce(connection, [Sidekiq::Debouncer::SET, key], [args_stringified, time, @debounce_key_ttl])
          end

          # prevent normal sidekiq flow
          false
        end

        def debounce_key(klass, job, options)
          method = options[:by]
          result = method.is_a?(Symbol) ? klass.send(method, job["args"]) : method.call(job["args"])
          "debounce/v3/#{klass.name}/#{result}"
        end

        def debounce_options(klass)
          options = klass.get_sidekiq_options["debounce"].transform_keys(&:to_sym)

          raise MissingArgumentError, "'by' attribute not provided" unless options[:by]
          raise MissingArgumentError, "'time' attribute not provided" unless options[:time]

          options
        end

        def testing?
          defined?(Sidekiq::Testing) && Sidekiq::Testing.enabled?
        end
      end
    end
  end
end
