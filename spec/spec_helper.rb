$LOAD_PATH.unshift "lib"

$TESTING = true # standard:disable Style/GlobalVars

require "rspec"
require "timecop"
require "parallel"
require "simplecov"
require "sidekiq/cli"
require "sidekiq/scheduled"
require "sidekiq/processor"
require "sidekiq/api"
require "sidekiq/testing"
require "rack/test"
require "rack/session"
require "sidekiq/web"
require "sidekiq-debouncer"
require "sidekiq/debouncer/web"

SimpleCov.start do
  add_filter "/spec/"
end

Sidekiq.default_configuration.logger.level = Logger::UNKNOWN

Sidekiq::Testing.disable!
Sidekiq::Testing.server_middleware do |chain|
  chain.add Sidekiq::Debouncer::Middleware::Server
end

RSpec.configure do |config|
  config.order = "random"
  config.color = true
end
