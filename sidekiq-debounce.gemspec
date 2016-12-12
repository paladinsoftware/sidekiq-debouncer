# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sidekiq/debounce/version'

Gem::Specification.new do |gem|
  gem.name          = 'sidekiq-debounce'
  gem.version       = Sidekiq::Debounce::VERSION
  gem.authors       = ['Sebastian Zuchmański']
  gem.email         = ['sebcioz@gmail.com']
  gem.description   = %q{}
  gem.summary       = %q{}
  gem.homepage      = 'https://github.com/paladinsoftware/sidekiq-debounce'
  gem.license       = 'MIT'

  gem.files         = `git ls-files`.split($/)
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = %w(lib)

  gem.add_dependency 'activesupport'
  gem.add_dependency 'sidekiq', '>= 2.5', '< 5.0'

  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'rspec-sidekiq'
  gem.add_development_dependency 'timecop'
  gem.add_development_dependency 'rspec-redis_helper'
  gem.add_development_dependency 'fakeredis'
end