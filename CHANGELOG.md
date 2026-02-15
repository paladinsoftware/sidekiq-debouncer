## [3.2.0] - 2026-02-15
- Support extra attributes ([#37](https://github.com/paladinsoftware/sidekiq-debouncer/pull/37))
- Fix loading order issues ([#36](https://github.com/paladinsoftware/sidekiq-debouncer/pull/36))
- Bump Ruby and Sidekiq versions ([#35](https://github.com/paladinsoftware/sidekiq-debouncer/pull/35))

## [3.1.0] - 2025-03-28
- Drop support for Ruby < 3.2.0
- Support for Sidekiq 8 ([#31](https://github.com/paladinsoftware/sidekiq-debouncer/pull/31), [#32](https://github.com/paladinsoftware/sidekiq-debouncer/pull/32))
- DragonflyDB support ([#29](https://github.com/paladinsoftware/sidekiq-debouncer/pull/29))

## [3.0.0] - 2024-10-22
- Complete rewrite of the library ([#25](https://github.com/paladinsoftware/sidekiq-debouncer/pull/25))
- Read only Web UI ([#26](https://github.com/paladinsoftware/sidekiq-debouncer/pull/26))
- Drop support for sidekiq 6.x and ruby 2.7 ([#28](https://github.com/paladinsoftware/sidekiq-debouncer/pull/28))
- Respect sidekiq_options overridden by .set ([#27](https://github.com/paladinsoftware/sidekiq-debouncer/pull/27))

**Upgrade notes:**
Since the job format changed, V3 won't debounce jobs enqueued with V2, although they'll still get executed

## [2.0.2] - 2023-03-13
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
