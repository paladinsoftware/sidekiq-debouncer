# frozen_string_literal: true

require "spec_helper"
require_relative "../../../support/context"
require_relative "../../../support/test_workers"
require_relative "../../../support/test_middlewares"

describe Sidekiq::Debouncer::Middleware::Client do
  include_context "sidekiq"

  context "task with debounce" do
    context "1 task" do
      it "executes it after 5 minutes" do
        TestWorker.perform_async("A", "job 1")

        expect(schedule_set.size).to eq(1)

        set_item = schedule_set.first
        expect(set_item.value).to eq("debounce/v3/TestWorker/A")
        expect(set_item.score).to eq((time_start + 5 * 60).to_i)
      end

      it "doesnt land in queue" do
        TestWorker.perform_async("A", "job 1")

        expect(queue.size).to eq(0)
      end

      it "saves job in set" do
        TestWorker.perform_async("A", "job 1")

        Sidekiq.redis do |connection|
          stored = connection.call("ZRANGE", "debounce/v3/TestWorker/A", "-inf", "+inf", "BYSCORE")
          parsed = Sidekiq.load_json(stored.first)
          expect(parsed["args"]).to eq(["A", "job 1"])
          expect(parsed["class"]).to eq("TestWorker")
        end
      end

      it "allows overriding debounce options via Sidekiq's .set API" do
        TestWorker
          .set(debounce: {by: ->(jargs) { jargs[0] }, time: 10 * 60})
          .perform_async("A", "job 1")

        expect(schedule_set.size).to eq(1)
        expect(queue.size).to eq(0)

        set_item = schedule_set.first
        expect(set_item.value).to eq("debounce/v3/TestWorker/A")
        expect(set_item.score).to eq((time_start + 10 * 60).to_i)
      end

      it "executes it after 5 minutes for symbol debounce" do
        expect(TestWorkerWithSymbolAsDebounce).to receive(:debounce_method).with(["A", "job 1"]).once.and_call_original
        TestWorkerWithSymbolAsDebounce.perform_async("A", "job 1")

        expect(schedule_set.size).to eq(1)

        set_item = schedule_set.first
        expect(set_item.value).to eq("debounce/v3/TestWorkerWithSymbolAsDebounce/A")
        expect(set_item.score).to eq((time_start + 5 * 60).to_i)
      end

      it "executes the rest of middleware stack" do
        TestWorker.perform_async("AB", "job 33")

        expect(schedule_set.size).to eq(1)

        Sidekiq.redis do |connection|
          stored = connection.call("ZRANGE", "debounce/v3/TestWorker/ABC", "-inf", "+inf", "BYSCORE")
          parsed = Sidekiq.load_json(stored.first)
          expect(parsed["args"]).to eq(["ABC", "job 34"])
        end
      end
    end

    context "1 task, 3 minutes break, 1 task" do
      it "executes both tasks after 8 minutes for multiple arguments" do
        TestWorkerWithMultipleArguments.perform_async(1, 5)

        Timecop.freeze(time_start + 3 * 60)
        TestWorkerWithMultipleArguments.perform_async(3, 3)

        expect(schedule_set.size).to eq(1)

        set_item = schedule_set.first
        expect(set_item.value).to eq("debounce/v3/TestWorkerWithMultipleArguments/6")
        expect(set_item.score).to eq((time_start + 8 * 60).to_i)

        expect(queue.size).to eq(0)
      end

      it "executes both tasks after 8 minutes" do
        TestWorker.perform_async("A", "job 1")

        Timecop.freeze(time_start + 3 * 60)
        TestWorker.perform_async("A", "job 2")

        expect(schedule_set.size).to eq(1)

        set_item = schedule_set.first
        expect(set_item.value).to eq("debounce/v3/TestWorker/A")
        expect(set_item.score).to eq((time_start + 8 * 60).to_i)

        expect(queue.size).to eq(0)
      end

      it "executes both tasks after 8 minutes for symbol debounce" do
        TestWorkerWithSymbolAsDebounce.perform_async("A", "job 1")

        Timecop.freeze(time_start + 3 * 60)
        TestWorkerWithSymbolAsDebounce.perform_async("A", "job 2")

        expect(schedule_set.size).to eq(1)

        set_item = schedule_set.first
        expect(set_item.value).to eq("debounce/v3/TestWorkerWithSymbolAsDebounce/A")
        expect(set_item.score).to eq((time_start + 8 * 60).to_i)

        expect(queue.size).to eq(0)
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

    context "invalid options" do
      it "raises an error when sidekiq_options is missing an option" do
        expect { InvalidWorker.perform_async("abc") }.to raise_error(Sidekiq::Debouncer::MissingArgumentError)
      end

      it "raises an error when Sidekiq's .set API doesn't pass ALL sidekiq_options" do
        expect { TestWorker.set(debounce: {time: 5 * 60}).perform_async("abc") }.to raise_error(Sidekiq::Debouncer::MissingArgumentError)
      end
    end

    context "debounce method" do
      it "warns the method is deprecated" do
        allow(TestWorker).to receive(:warn)

        TestWorker.debounce("A", "job 1")

        expect(schedule_set.size).to eq(1)

        set_item = schedule_set.first
        expect(set_item.value).to eq("debounce/v3/TestWorker/A")
        expect(set_item.score).to eq((time_start + 5 * 60).to_i)

        expect(TestWorker).to have_received(:warn).with(/debounce method is deprecated/)
      end
    end

    context "multiprocess safety" do
      it "is safe" do
        Parallel.each((1..1000).to_a, in_processes: 10) do |i|
          TestWorker.perform_async("A", i)
        end

        expect(schedule_set.size).to eq(1)

        set_item = schedule_set.first
        expect(set_item.value).to eq("debounce/v3/TestWorker/A")

        Sidekiq.redis do |connection|
          stored = connection.call("ZRANGE", "debounce/v3/TestWorker/A", "-inf", "+inf", "BYSCORE")
          expect(stored.map { Sidekiq.load_json(_1)["args"][1] }).to match_array((1..1000).to_a)
        end

        expect(queue.size).to eq(0)
      end
    end

    context "sidekiq testing fake mode" do
      it "uses standard sidekiq flow" do
        Sidekiq::Testing.fake! do
          TestWorker.perform_async("A", "job 1")

          expect(schedule_set.size).to eq(0)
          expect(TestWorker.jobs.size).to eq(1)

          expect_any_instance_of(TestWorker).to receive(:perform).with([["A", "job 1"]])
          TestWorker.drain
        end
      end
    end

    context "sidekiq testing inline mode" do
      it "uses standard sidekiq flow" do
        Sidekiq::Testing.inline! do
          expect_any_instance_of(TestWorker).to receive(:perform).with([["A", "job 1"]])

          TestWorker.perform_async("A", "job 1")

          expect(schedule_set.size).to eq(0)
          expect(TestWorker.jobs.size).to eq(0)
        end
      end
    end
  end

  context "normal job" do
    it "ignores debounce logic" do
      NormalWorker.perform_async("abc")

      expect(schedule_set.size).to eq(0)
      expect(queue.first["debounce_key"]).to be_nil
    end
  end
end
