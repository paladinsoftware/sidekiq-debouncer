# frozen_string_literal: true

module Sidekiq
  module Debouncer
    module Middleware
      # wrap args into array because sidekiq uses splat while calling perform
      class Server
        include Sidekiq::ServerMiddleware

        def call(_worker, job, _queue)
          if job.key?("debounce_key")
            job["args"] = [job["args"]]
          end

          yield
        end
      end
    end
  end
end
