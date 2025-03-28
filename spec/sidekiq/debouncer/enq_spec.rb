# frozen_string_literal: true

require "spec_helper"
require_relative "../../support/context"
require_relative "../../support/test_workers"
require_relative "../../support/test_middlewares"

describe Sidekiq::Debouncer::Enq do
  include_context "sidekiq"

  # Enq is used by puller

  context "1 task, 3 minutes break, 1 task, 6 minutes break, 2 tasks" do
    it "executes two tasks after 8 minutes, the last one in 14 minutes" do
      TestWorker.perform_async("A", "job 1")

      Timecop.freeze(time_start + 3 * 60)
      TestWorker.perform_async("A", "job 2")

      Timecop.freeze(time_start + 9 * 60)
      puller.enqueue

      TestWorker.perform_async("A", "job 3")
      expect(schedule_set.size).to eq(1)

      queue_job = sample_queue.first
      expect(queue_job.args).to eq([["A", "job 1"], ["A", "job 2"]])

      processor.send(:process_one)
      TestWorker.perform_async("A", "job 4")
      expect(schedule_set.size).to eq(1)

      set_item = schedule_set.first
      expect(set_item.value).to eq("debounce/v3/TestWorker/A")
      expect(set_item.score).to eq((time_start + 14 * 60).to_i)
    end
  end

  context "1 task, 6 minutes break, 1 task" do
    it "executes first task, the second one in 11 minutes" do
      TestWorker.perform_async("A", "job 1")

      Timecop.freeze(time_start + 6 * 60)
      puller.enqueue

      TestWorker.perform_async("A", "job 2")

      queue_job = sample_queue.first

      expect(queue_job.args).to eq([["A", "job 1"]])
      processor.send(:process_one)

      set_item = schedule_set.first
      expect(set_item.value).to eq("debounce/v3/TestWorker/A")
      expect(set_item.score).to eq((time_start + 11 * 60).to_i)

      Timecop.freeze(time_start + 12 * 60)
      puller.enqueue

      queue_job = sample_queue.first
      expect(queue_job.args).to eq([["A", "job 2"]])
    end
  end

  context "multiprocess safety" do
    it "is safe" do
      TestWorker.perform_async("A", 1)

      expect(schedule_set.size).to eq(1)

      set_item = schedule_set.first
      expect(set_item.value).to eq("debounce/v3/TestWorker/A")

      expect(puller.instance_variable_get(:@enq)).to receive(:zpopbyscore_withscore).twice.and_wrap_original do |original_method, *args|
        original_method.call(*args).tap { TestWorker.perform_async("A", 2) }
      end

      Timecop.freeze(time_start + 10 * 60)
      puller.enqueue

      expect(sample_queue.size).to eq(1)
      expect(sample_queue.first.args).to eq([["A", 1]])
    end
  end
end
