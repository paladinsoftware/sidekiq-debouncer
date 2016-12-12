$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'rspec'
require 'fakeredis'
require 'fakeredis/rspec'
require 'rspec-sidekiq'
require 'timecop'

require 'sidekiq/debounce'

RSpec.configure do |config|
  config.order = 'random'
  config.color = true

  redis_opts = { url: "redis://127.0.0.1:6379/1", namespace: "example" }
  redis_opts.merge!(:driver => Redis::Connection::Memory) if defined?(Redis::Connection::Memory)

  Sidekiq.configure_client do |config|
    config.redis = redis_opts
  end

  Sidekiq.configure_server do |config|
    config.redis = redis_opts
  end
end