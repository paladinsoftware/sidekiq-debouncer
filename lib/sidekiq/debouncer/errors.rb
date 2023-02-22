# frozen_string_literal: true

module Sidekiq
  module Debouncer
    Error = Class.new(StandardError)
    NotSupportedError = Class.new(Error)
    MissingArgumentError = Class.new(Error)
  end
end
