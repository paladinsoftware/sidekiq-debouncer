# Sidekiq::Debouncer
[![Maintainability](https://api.codeclimate.com/v1/badges/a4b87d864a8a0f69d2be/maintainability)](https://codeclimate.com/github/paladinsoftware/sidekiq-debouncer/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/a4b87d864a8a0f69d2be/test_coverage)](https://codeclimate.com/github/paladinsoftware/sidekiq-debouncer/test_coverage)

Sidekiq extension that adds the ability to debounce job execution.

Worker will postpone its execution after `wait time` have elapsed since the last time it was invoked. Useful for implementing behavior that should only happen after the input has stopped arriving. For example: sending group email to the user after he stopped interacting with the application.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'sidekiq-debouncer'
```

And then execute:

    $ bundle

## Basic usage

In a worker, include `Sidekiq::Debouncer` module, specify debounce wait time (in seconds):

```ruby
class MyWorker
  include Sidekiq::Worker
  include Sidekiq::Debouncer

  sidekiq_options(
    debounce: {
      time: 5 * 60
    }
  )

  def perform(group)
    group.each do
      # do some work with group
    end
  end
end
```

You can specify your own debounce method. In this case worker will be debounced if first argument matches.
```ruby
class MyWorker
  include Sidekiq::Worker
  include Sidekiq::Debouncer

  sidekiq_options(
    debounce: {
      time: 5 * 60,
      by: -> (job_args) {
        job_args[0]
      }
    }
  )

  def perform(group)
    group.each do
      # do some work with group
    end
  end
end
```

You can also pass symbol as `debounce_by` matching class method.
```ruby
class MyWorker
  include Sidekiq::Worker
  include Sidekiq::Debouncer

  sidekiq_options(
    debounce: {
      time: 5 * 60,
      by: :debounce_method
    }
  )
  
  def self.debounce_method(job_args)
    job_args[0]
  end

  def perform(group)
    group.each do
      # do some work with group
    end
  end
end
```


In the application, call `MyWorker.debounce(...)`. Everytime you call this function, `MyWorker`'s execution will be postponed by 5 minutes. After that time `MyWorker` will receive a method call `perform` with an array of arguments that were provided to the `MyWorker.debounce(...)`.

## License

MIT Licensed. See LICENSE.txt for details.
