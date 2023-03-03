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
