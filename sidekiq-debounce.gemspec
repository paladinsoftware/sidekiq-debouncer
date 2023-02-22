# frozen_string_literal: true

require_relative "./lib/sidekiq/debouncer/version"

Gem::Specification.new do |gem|
  gem.name = "sidekiq-debouncer"
  gem.version = Sidekiq::Debouncer::VERSION
  gem.authors = ["Sebastian Zuchmański", "Karol Bąk"]
  gem.email = ["sebcioz@gmail.com", "kukicola@gmail.com"]
  gem.summary = "Sidekiq extension that adds the ability to debounce job execution"
  gem.description = <<~DESCRIPTION
    Worker will postpone its execution after `wait time` have elapsed since the last time it was invoked.
    Useful for implementing behavior that should only happen after the input has stopped arriving.
  DESCRIPTION
  gem.homepage = "https://github.com/paladinsoftware/sidekiq-debouncer"
  gem.license = "MIT"
  gem.required_ruby_version = ">= 2.7.0"

  gem.files = Dir.glob("lib/**/*") + [
    "CHANGELOG.md",
    "LICENSE.txt",
    "README.md",
    "sidekiq-debounce.gemspec"
  ]

  gem.add_dependency "sidekiq", ">= 6.5", "< 8.0"

  gem.add_development_dependency "rspec", "~> 3.12.0"
  gem.add_development_dependency "timecop", "~> 0.9.6"
  gem.add_development_dependency "simplecov", "~> 0.22.0"
  gem.add_development_dependency "parallel", "~> 1.22.1"
  gem.add_development_dependency "standard", "~> 1.24.3"
end
