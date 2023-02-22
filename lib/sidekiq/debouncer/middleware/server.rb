# frozen_string_literal: true

module Sidekiq
  module Debouncer
    module Middleware
      # Server middleware removes debounce key from redis before executing the job
      class Server
        include Sidekiq::ServerMiddleware

        def call(_worker, job, _queue)
          if job.key?("debounce_key")
            # skip if job comes from dead or retry set
            unless job.key?("failed_at")
              redis do |connection|
                connection.call("DEL", job["debounce_key"])
              end
            end

            job["args"] = [job["args"]] # wrap args into array because sidekiq uses splat while calling perform
          end

          yield
        end
      end
    end
  end
end
