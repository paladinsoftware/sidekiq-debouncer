## Unreleased
- support Sidekiq::Testing

## [2.0.1] - 2023-03-04
- don't remove debounce key in redis to avoid invalid debouncing

## [2.0.0] - 2023-02-28
Complete rewrite of the library:  
- Instead of iterating through whole schedule set, sidekiq-debouncer will now cache debounce key in redis with a reference to the job.
Thanks to that there is a huge performance boost compared to V1. With 1k jobs in schedule set it's over 100x faster.
The difference is even bigger with larger amount of jobs.
- Debouncing is now handled by Lua script instead of pure ruby so it's process safe.

Breaking changes:
- Including `Sidekiq::Debouncer` in the workers and using `debounce` method is now deprecated. Use `perform_async` instead.
- Setup requires middlewares to be added in sidekiq configuration.
- `by` attribute is now required
- dropped support for Ruby < 2.7 and Sidekiq < 6.5
