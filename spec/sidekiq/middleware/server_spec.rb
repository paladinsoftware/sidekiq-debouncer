# frozen_string_literal: true

require "spec_helper"
require_relative "../../support/context"
require_relative "../../support/test_workers"
require_relative "../../support/test_middlewares"

describe Sidekiq::Debouncer::Middleware::Client do
  include_context "sidekiq"

  context "job with debounce" do
    it "removes debounce key and wrap arguments" do
      TestWorker.perform_async("A", "job 1")
      TestWorker.perform_async("A", "job 2")

      expect(Sidekiq.redis { |con| con.call("GET", "debounce/TestWorker/A") }).not_to be_nil

      Timecop.freeze(time_start + 10 * 60)
      puller.enqueue

      expect_any_instance_of(TestWorker).to receive(:perform).with([["A", "job 1"], ["A", "job 2"]]).and_call_original
      processor.process_one

      expect(Sidekiq.redis { |con| con.call("GET", "debounce/TestWorker/A") }).to be_nil
    end
  end

  context "retry job" do
    it "removes debounce key and wrap arguments only on first call" do
      TestWorker.perform_async("A", "job 1")

      expect(Sidekiq.redis { |con| con.call("GET", "debounce/TestWorker/A") }).not_to be_nil

      Timecop.freeze(time_start + 10 * 60)
      puller.enqueue # job now in the queue

      allow_any_instance_of(TestWorker).to receive(:perform).with([["A", "job 1"]]).and_raise("something")
      processor.process_one rescue nil # standard:disable Style/RescueModifier

      expect(Sidekiq.redis { |con| con.call("GET", "debounce/TestWorker/A") }).to be_nil

      Timecop.freeze(time_start + 20 * 60)
      puller.enqueue # job in the queue again

      TestWorker.perform_async("A", "job 2")
      expect(Sidekiq.redis { |con| con.call("GET", "debounce/TestWorker/A") }).not_to be_nil

      processor.process_one rescue nil # standard:disable Style/RescueModifier

      expect(Sidekiq.redis { |con| con.call("GET", "debounce/TestWorker/A") }).not_to be_nil
    end
  end

  context "normal job" do
    it "works normally" do
      NormalWorker.perform_async(1)

      puller.enqueue
      expect_any_instance_of(NormalWorker).to receive(:perform).with(1).and_call_original

      processor.process_one
    end
  end
end
