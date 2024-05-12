# frozen_string_literal: true

shared_context "sidekiq" do
  let(:time_start) { Time.new(2016, 1, 1, 12, 0, 0, 0) }
  let(:sidekiq_config) do
    sidekiq_version = Gem::Version.new(Sidekiq::VERSION)
    if sidekiq_version >= Gem::Version.new("7.0")
      Sidekiq.default_configuration.tap do |config|
        config.queues = ["default", "sample_queue"]
      end
    else
      Sidekiq.queues = ["default", "sample_queue"]
      Sidekiq[:fetch] = Sidekiq::BasicFetch.new(Sidekiq)
      Sidekiq
    end
  end
  let(:queue) { Sidekiq::Queue.new("default") }
  let(:sample_queue) { Sidekiq::Queue.new("sample_queue") }
  let(:puller) { ::Sidekiq::Debouncer::Poller.new(sidekiq_config) }
  let(:schedule_set) { Sidekiq::Debouncer::Set.new }
  let(:processor) do
    sidekiq_version = Gem::Version.new(Sidekiq::VERSION)
    if sidekiq_version >= Gem::Version.new("7.0")
      ::Sidekiq::Processor.new(sidekiq_config.default_capsule) { |*args| }
    else
      ::Sidekiq::Processor.new(sidekiq_config) { |*args| }
    end
  end

  before do
    Timecop.freeze(time_start)
    Sidekiq.redis do |connection|
      connection.call("FLUSHDB")
      connection.call("SCRIPT", "FLUSH")
    end
  end
end
