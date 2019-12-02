$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'rspec'
require 'redis/namespace'
require 'rspec-sidekiq'
require 'timecop'

require 'simplecov'
SimpleCov.start

require 'sidekiq/debouncer'

RSpec.configure do |config|
  config.order = 'random'
  config.color = true

  Sidekiq.configure_server do |config|
    config.redis[:namespace] = { namespace: 'sidekiq-debouncer' }
  end
end
