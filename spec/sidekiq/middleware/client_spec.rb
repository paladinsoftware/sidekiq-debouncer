# frozen_string_literal: true

require "spec_helper"
require_relative "../../support/test_workers"
require_relative "../../support/test_middlewares"

describe Sidekiq::Debouncer::Middleware::Client do
  let(:time_start) { Time.new(2016, 1, 1, 12, 0, 0) }
  let(:sidekiq_config) do
    sidekiq_version = Gem::Version.new(Sidekiq::VERSION)
    if sidekiq_version >= Gem::Version.new('7.0')
      Sidekiq.default_configuration
    else
      Sidekiq.queues = ["default"]
      Sidekiq
    end
  end
  let(:puller) { ::Sidekiq::Scheduled::Poller.new(sidekiq_config) }
  let(:schedule_set) { Sidekiq::ScheduledSet.new }
  let(:queue) { Sidekiq::Queue.new("default") }

  before do
    Timecop.freeze(time_start)
    Sidekiq.redis do |connection|
      connection.call("FLUSHDB")
      connection.call("SCRIPT", "FLUSH")
    end
  end

  context "task with debounce" do
    context "1 task" do
      it "executes it after 5 minutes" do
        TestWorker.perform_async("A", "job 1")

        expect(schedule_set.size).to eq(1)

        group = schedule_set.first

        expect(group.args).to eq([["A", "job 1"]])
        expect(group.at.to_i).to eq((time_start + 5 * 60).to_i)
        expect(queue.size).to eq(0)
      end

      it "executes it after 5 minutes for symbol debounce" do
        expect(TestWorkerWithSymbolAsDebounce).to receive(:debounce_method).with(["A", "job 1"]).once.and_call_original
        TestWorkerWithSymbolAsDebounce.perform_async("A", "job 1")

        expect(schedule_set.size).to eq(1)

        group = schedule_set.first

        expect(group.args).to eq([["A", "job 1"]])
        expect(group.at.to_i).to eq((time_start + 5 * 60).to_i)
        expect(queue.size).to eq(0)
      end

      it "executes the rest of middleware stack" do
        TestWorker.perform_async("A", "job 1")

        expect(schedule_set.size).to eq(1)

        group = schedule_set.first

        expect(group["test_1"]).to be_truthy
        expect(group["test_2"]).to be_truthy
      end

      it "saves information about debounce_key" do
        TestWorker.perform_async("A", "job 1")

        expect(schedule_set.size).to eq(1)

        group = schedule_set.first

        expect(group["debounce_key"]).to eq("debounce/TestWorker/A")
      end

      it "saves debounce key" do
        TestWorker.perform_async("A", "job 1")

        expect(Sidekiq.redis { |con| con.call("GET", "debounce/TestWorker/A") }).not_to be_nil
      end
    end

    context "1 task, 3 minutes break, 1 task" do
      it "executes both tasks after 8 minutes for multiple arguments" do
        TestWorkerWithMultipleArguments.perform_async(1, 5)

        Timecop.freeze(time_start + 3 * 60)
        TestWorkerWithMultipleArguments.perform_async(3, 3)

        expect(schedule_set.size).to eq(1)
        group = schedule_set.first

        expect(group.args).to eq([[1, 5], [3, 3]])
        expect(group.at.to_i).to be((time_start + 8 * 60).to_i)
        expect(queue.size).to eq(0)
      end

      it "executes both tasks after 8 minutes" do
        TestWorker.perform_async("A", "job 1")

        Timecop.freeze(time_start + 3 * 60)
        TestWorker.perform_async("A", "job 2")

        expect(schedule_set.size).to eq(1)
        group = schedule_set.first

        expect(group.args).to eq([["A", "job 1"], ["A", "job 2"]])
        expect(group.at.to_i).to be((time_start + 8 * 60).to_i)
        expect(queue.size).to eq(0)
      end

      it "executes both tasks after 8 minutes for symbol debounce" do
        TestWorkerWithSymbolAsDebounce.perform_async("A", "job 1")

        Timecop.freeze(time_start + 3 * 60)
        TestWorkerWithSymbolAsDebounce.perform_async("A", "job 2")

        expect(schedule_set.size).to eq(1)
        group = schedule_set.first
        expect(group.args).to eq([["A", "job 1"], ["A", "job 2"]])
        expect(group.at.to_i).to be((time_start + 8 * 60).to_i)
        expect(queue.size).to eq(0)
      end
    end

    context "1 task, 3 minutes break, 1 task, 6 minutes break, 1 task" do
      it "executes two tasks after 8 minutes, the last one in 14 minutes" do
        TestWorker.perform_async("A", "job 1")

        Timecop.freeze(time_start + 3 * 60)
        TestWorker.perform_async("A", "job 2")

        Timecop.freeze(time_start + 9 * 60)
        puller.enqueue

        TestWorker.perform_async("A", "job 3")
        expect(schedule_set.size).to eq(1)

        queue_job = queue.first
        scheduled = schedule_set.first

        expect(queue_job.args).to eq([["A", "job 1"], ["A", "job 2"]])
        expect(scheduled.args).to eq([["A", "job 3"]])
        expect(scheduled.at.to_i).to be((time_start + 14 * 60).to_i)
      end
    end

    context "1 task, 6 minutes break, 1 task" do
      it "executes first task, the second one in 11 minutes" do
        TestWorker.perform_async("A", "job 1")

        Timecop.freeze(time_start + 6 * 60)
        puller.enqueue

        TestWorker.perform_async("A", "job 2")

        queue_job = queue.first
        scheduled = schedule_set.first

        expect(queue_job.args).to eq([["A", "job 1"]])

        expect(scheduled.args).to eq([["A", "job 2"]])
        expect(scheduled.at.to_i).to be((time_start + 11 * 60).to_i)
      end
    end

    context "call using perform_in" do
      it "raises error" do
        expect { TestWorker.perform_in(30, "abc") }.to raise_error(Sidekiq::Debouncer::NotSupportedError)
      end
    end

    context "call using perform_at" do
      it "raises error" do
        expect { TestWorker.perform_at(Time.now.to_i + 30, "abc") }.to raise_error(Sidekiq::Debouncer::NotSupportedError)
      end
    end

    context "invalid attributes" do
      it "raises error" do
        expect { InvalidWorker.perform_async("abc") }.to raise_error(Sidekiq::Debouncer::MissingArgumentError)
      end
    end

    context "normal job" do
      it "ignores debounce logic" do
        NormalWorker.perform_async("abc")

        expect(schedule_set.size).to eq(0)
        expect(queue.first["debounce_key"]).to be_nil
      end
    end

    context "debounce method" do
      it "works like perform_async" do
        TestWorker.debounce("A", "job 1")

        expect(schedule_set.size).to eq(1)

        group = schedule_set.first

        expect(group.args).to eq([["A", "job 1"]])
        expect(group.at.to_i).to eq((time_start + 5 * 60).to_i)
        expect(queue.size).to eq(0)
      end
    end

    context "multiprocess safety" do
      it "is safe" do
        Parallel.each((1..1000).to_a, in_processes: 10) do |i|
          TestWorker.perform_async("A", i)
        end

        expect(schedule_set.size).to eq(1)

        group = schedule_set.first
        expect(group.args[0][0]).to eq("A")
        expect(group.args.map(&:last)).to match_array((1..1000).to_a)
        expect(queue.size).to eq(0)
      end
    end
  end
end
