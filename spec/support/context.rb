# frozen_string_literal: true

shared_context "sidekiq" do
  let(:time_start) { Time.new(2016, 1, 1, 12, 0, 0, 0) }
  let(:sidekiq_config) do
    Sidekiq.default_configuration.tap do |config|
      config.queues = ["default", "sample_queue"]
    end
  end
  let(:queue) { Sidekiq::Queue.new("default") }
  let(:sample_queue) { Sidekiq::Queue.new("sample_queue") }
  let(:puller) { ::Sidekiq::Debouncer::Poller.new(sidekiq_config) }
  let(:schedule_set) { Sidekiq::Debouncer::Set.new }
  let(:processor) { ::Sidekiq::Processor.new(sidekiq_config.default_capsule) { |*args| } }

  before do
    Timecop.freeze(time_start)
    Sidekiq.redis do |connection|
      connection.call("FLUSHDB")
      connection.call("SCRIPT", "FLUSH")
    end
  end
end
