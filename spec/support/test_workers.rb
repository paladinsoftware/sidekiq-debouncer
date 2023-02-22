# frozen_string_literal: true

class TestWorker
  include Sidekiq::Worker
  include Sidekiq::Debouncer

  sidekiq_options(
    debounce: {
      time: 5 * 60,
      by: ->(job_args) {
        job_args[0]
      }
    }
  )

  def perform(group)
  end
end

class TestWorkerWithMultipleArguments
  include Sidekiq::Worker

  sidekiq_options(
    debounce: {
      time: 5 * 60,
      by: ->(job_args) {
        job_args[0] + job_args[1]
      }
    }
  )

  def perform(group)
  end
end

class TestWorkerWithSymbolAsDebounce
  include Sidekiq::Worker

  sidekiq_options(
    debounce: {
      time: 5 * 60,
      by: :debounce_method
    }
  )

  def self.debounce_method(args)
    args[0]
  end

  def perform(group)
  end
end

class NormalWorker
  include Sidekiq::Worker

  def perform(args)
  end
end

class InvalidWorker
  include Sidekiq::Worker

  sidekiq_options(
    debounce: {
      time: 5 * 60
    }
  )

  def perform(group)
  end
end
