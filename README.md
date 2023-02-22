# Sidekiq::Debouncer

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

Add middlewares to sidekiq:

```ruby
Sidekiq.configure_client do |config|
  config.client_middleware do |chain|
    chain.add Sidekiq::Debouncer::Middleware::Client
  end
end

Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    chain.add Sidekiq::Debouncer::Middleware::Server
  end
end
```

Add debounce option to worker with `by` and `time` keys:
```ruby
class MyWorker
  include Sidekiq::Worker

  sidekiq_options(
    debounce: {
      by: -> (args) { args[0] }, # debounce by first argument only
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

You can also pass symbol as `debounce.by` matching class method.
```ruby
class MyWorker
  include Sidekiq::Worker

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

Keep in mind that the result of the debounce method will be converted to string, so make sure it doesn't return any objects that don't implement `to_s` method.

In the application, call `MyWorker.perform_async(...)` as usual. Everytime you call this function, `MyWorker`'s execution will be postponed by 5 minutes. After that time `MyWorker` will receive a method call `perform` with an array of arguments that were provided to the `MyWorker.perform_async(...)` calls.

To avoid keeping leftover keys in redis (for example, when job was manually removed from schedule set), all additional keys are created with TTL.
It's 7 days by default and should be ok in most of the cases. If you are debouncing your jobs in higher interval than that, you can overwrite this setting:

```ruby
Sidekiq.configure_client do |config|
  config.client_middleware do |chain|
    chain.add Sidekiq::Debouncer::Middleware::Client, ttl: 60 * 60 * 24 * 30 # 30 days
  end
end
```

## Testing

In order to test the behavior of `sidekiq-debouncer` it is necessary to disable testing mode. It is the limitation of internal implementation.

## License

MIT Licensed. See LICENSE.txt for details.

## Notes

This gem was renamed from `sidekiq-debouce` due to name conflict on rubygems.
