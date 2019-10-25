# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sidekiq/debouncer/version'

Gem::Specification.new do |gem|
  gem.name          = 'sidekiq-debouncer'
  gem.version       = Sidekiq::Debouncer::VERSION
  gem.authors       = ['Sebastian Zuchmański']
  gem.email         = ['sebcioz@gmail.com']
  gem.description   = %q{}
  gem.summary       = %q{}
  gem.homepage      = 'https://github.com/paladinsoftware/sidekiq-debouncer'
  gem.license       = 'MIT'

  gem.files         = `git ls-files`.split($/)
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = %w(lib)

  gem.add_dependency 'activesupport'
  gem.add_dependency 'sidekiq', '>= 5.0'

  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'rspec-sidekiq'
  gem.add_development_dependency 'timecop'
  gem.add_development_dependency 'rspec-redis_helper'
  gem.add_development_dependency 'redis-namespace'
end
