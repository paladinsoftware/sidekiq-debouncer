$LOAD_PATH.unshift "lib"

$TESTING = true # standard:disable Style/GlobalVars

require "rspec"
require "timecop"
require "parallel"
require "simplecov"
require "sidekiq/scheduled"
require "sidekiq/processor"
require "sidekiq/api"
require "sidekiq/testing"

SimpleCov.start do
  add_filter "/spec/"
end

require "sidekiq-debouncer"

sidekiq_version = Gem::Version.new(Sidekiq::VERSION)
if sidekiq_version >= Gem::Version.new("7.0")
  Sidekiq.default_configuration.logger.level = Logger::UNKNOWN
else
  Sidekiq.logger.level = Logger::UNKNOWN
end

Sidekiq::Testing.disable!
Sidekiq::Testing.server_middleware do |chain|
  chain.add Sidekiq::Debouncer::Middleware::Server
end

RSpec.configure do |config|
  config.order = "random"
  config.color = true
end
