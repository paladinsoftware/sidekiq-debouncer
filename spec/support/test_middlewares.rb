# frozen_string_literal: true

class TestMiddleware
  def call(_worker_class, job, _queue, _redis_pool)
    job["test_1"] = true
    yield
  end
end

class SecondTestMiddleware
  def call(_worker_class, job, _queue, _redis_pool)
    job["test_2"] = true
    yield
  end
end

Sidekiq.configure_client do |config|
  config.client_middleware do |chain|
    chain.add TestMiddleware
    chain.add Sidekiq::Debouncer::Middleware::Client
    chain.add SecondTestMiddleware
  end

  config.server_middleware do |chain|
    chain.add Sidekiq::Debouncer::Middleware::Server
  end
end
