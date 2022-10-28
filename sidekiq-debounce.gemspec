# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sidekiq/debouncer/version'

Gem::Specification.new do |gem|
  gem.name          = 'sidekiq-debouncer'
  gem.version       = Sidekiq::Debouncer::VERSION
  gem.authors       = ['Sebastian Zuchmański', 'Karol Bąk']
  gem.email         = ['sebcioz@gmail.com', 'karol.bak@paladinsoftware.com']
  gem.description   = %q{Sidekiq extension that adds the ability to debounce job execution.}
  gem.summary       = %q{}
  gem.homepage      = 'https://github.com/paladinsoftware/sidekiq-debouncer'
  gem.license       = 'MIT'
  gem.required_ruby_version = '>= 2.3.0'

  gem.files         = `git ls-files`.split($/)
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = %w(lib)

  gem.add_dependency 'sidekiq', '>= 5.0', '< 8.0'

  gem.add_development_dependency 'rspec', '~> 3.9.0'
  gem.add_development_dependency 'rspec-sidekiq', '~> 3.0.3'
  gem.add_development_dependency 'timecop', '~> 0.9.1'
  gem.add_development_dependency 'rspec-redis_helper', '~> 0.1.2'
  gem.add_development_dependency 'redis-namespace', '~> 1.6.0'
  gem.add_development_dependency 'simplecov', '~> 0.16.1'
end
