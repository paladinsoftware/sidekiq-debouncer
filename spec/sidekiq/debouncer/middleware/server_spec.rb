# frozen_string_literal: true

require "spec_helper"
require_relative "../../../support/context"
require_relative "../../../support/test_workers"
require_relative "../../../support/test_middlewares"

describe Sidekiq::Debouncer::Middleware::Server do
  include_context "sidekiq"

  context "job with debounce" do
    it "removes debounce key and wrap arguments" do
      TestWorker.perform_async("A", "job 1")
      TestWorker.perform_async("A", "job 2")

      expect(Sidekiq.redis { |con| con.call("ZCARD", "debounce/TestWorker/A") }).not_to be_nil

      Timecop.freeze(time_start + 10 * 60)
      puller.enqueue

      expect_any_instance_of(TestWorker).to receive(:perform).with(match_array([["A", "job 1"], ["A", "job 2"]])).and_call_original
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

  context "multiprocess safety" do
    it "is safe" do
      TestWorker.perform_async("A", 1)

      expect(schedule_set.size).to eq(1)

      set_item = schedule_set.first
      expect(set_item.value).to eq("debounce/TestWorker/A")

      expect(puller.instance_variable_get(:@enq)).to receive(:zpopbyscore_withscore).twice.and_wrap_original do |original_method, *args|
        original_method.call(*args).tap { TestWorker.perform_async("A", 2) }
      end

      Timecop.freeze(time_start + 10 * 60)
      puller.enqueue

      expect(queue.size).to eq(1)
      expect(queue.first.args).to eq([["A", 1]])
    end
  end
end
