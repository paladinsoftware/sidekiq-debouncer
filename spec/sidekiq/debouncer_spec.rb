require 'spec_helper'

class TestWorker
  include Sidekiq::Worker
  include Sidekiq::Debouncer

  sidekiq_options(
    debounce: {
      time: 5 * 60,
      by: -> (job_args) {
        job_args[0]
      }
    }
  )

  # group - array of arguments for single job
  def perform(group)
    group.each do
      # do some work with group
    end
  end
end

class TestWorkerWithMultipleArguments
  include Sidekiq::Worker
  include Sidekiq::Debouncer

  sidekiq_options(
    debounce: {
      time: 5 * 60,
      by: -> (job_args) {
        job_args[0] + job_args[1]
      }
    }
  )

  # group - array of arguments for single job
  def perform(group)
    group.each do
      # do some work with group
    end
  end
end

class TestWorkerWithSymbolAsDebounce
  include Sidekiq::Worker
  include Sidekiq::Debouncer

  sidekiq_options(
    debounce: {
      time: 5 * 60,
      by: :debounce_method
    }
  )

  def self.debounce_method(args)
    args[0]
  end

  # group - array of arguments for single job
  def perform(group)
    group.each do
      # do some work with group
    end
  end
end

describe Sidekiq::Debouncer do
  let(:time_start) { Time.new(2016, 1, 1, 12, 0, 0) }

  before do
    Timecop.freeze(time_start)
    Sidekiq::ScheduledSet.new.clear
  end

  context "1 type of tasks" do
    context "1 task" do
      it "executes it after 5 minutes" do
        TestWorker.debounce("A", "job 1")

        expect(Sidekiq::ScheduledSet.new.size).to eq(1)

        group = Sidekiq::ScheduledSet.new.first
        expect(group.args[0]).to eq([["A", "job 1"]])
        expect(group.at.to_i).to eq((time_start + 5 * 60).to_i)
      end

      it "executes it after 5 minutes for symbol debounce" do
        expect(TestWorkerWithSymbolAsDebounce).to receive(:debounce_method).with(["A", "job 1"]).once.and_call_original
        TestWorkerWithSymbolAsDebounce.debounce("A", "job 1")

        expect(Sidekiq::ScheduledSet.new.size).to eq(1)

        group = Sidekiq::ScheduledSet.new.first
        expect(group.args[0]).to eq([["A", "job 1"]])
        expect(group.at.to_i).to eq((time_start + 5 * 60).to_i)
      end
    end

    context "1 task, 3 minutes break, 1 task" do
      it "executes both tasks after 8 minutes for multiple arguments" do
        TestWorkerWithMultipleArguments.debounce(1, 5)
        Timecop.freeze(time_start + 3 * 60)
        TestWorkerWithMultipleArguments.debounce(3, 3)

        expect(Sidekiq::ScheduledSet.new.size).to eq(1)
        group = Sidekiq::ScheduledSet.new.first
        expect(group.args[0]).to eq([[1, 5], [3, 3]])
        expect(group.at.to_i).to be((time_start + 8 * 60).to_i)
      end

      it "executes both tasks after 8 minutes" do
        TestWorker.debounce("A", "job 1")
        Timecop.freeze(time_start + 3 * 60)
        TestWorker.debounce("A", "job 2")

        expect(Sidekiq::ScheduledSet.new.size).to eq(1)
        group = Sidekiq::ScheduledSet.new.first
        expect(group.args[0]).to eq([["A", "job 1"], ["A", "job 2"]])
        expect(group.at.to_i).to be((time_start + 8 * 60).to_i)
      end

      it "executes both tasks after 8 minutes for symbol debounce" do
        TestWorkerWithSymbolAsDebounce.debounce("A", "job 1")
        Timecop.freeze(time_start + 3 * 60)
        TestWorkerWithSymbolAsDebounce.debounce("A", "job 2")

        expect(Sidekiq::ScheduledSet.new.size).to eq(1)
        group = Sidekiq::ScheduledSet.new.first
        expect(group.args[0]).to eq([["A", "job 1"], ["A", "job 2"]])
        expect(group.at.to_i).to be((time_start + 8 * 60).to_i)
      end
    end

    context "1 task, 3 minutes break, 1 task, 6 minutes break, 1 task" do
      it "executes two tasks after 8 minutes, the last one in 14 minutes" do
        TestWorker.debounce("A", "job 1")
        Timecop.freeze(time_start + 3 * 60)
        TestWorker.debounce("A", "job 2")
        Timecop.freeze(time_start + 3 * 60 + 6 * 60)
        TestWorker.debounce("A", "job 3")

        expect(Sidekiq::ScheduledSet.new.size).to eq(2)

        groups = Sidekiq::ScheduledSet.new.to_a.sort_by { |g| g.at.to_i }

        expect(groups[0].args[0]).to eq([["A", "job 1"], ["A", "job 2"]])
        expect(groups[0].at.to_i).to be((time_start + 8 * 60).to_i)

        expect(groups[1].args[0]).to eq([["A", "job 3"]])
        expect(groups[1].at.to_i).to be((time_start + 14 * 60).to_i)
      end
    end

    context "1 task, 6 minutes break, 1 task" do
      it "executes first task, the second one in 11 minutes" do
        TestWorker.debounce("A", "job 1")
        Timecop.freeze(time_start + 6 * 60)
        TestWorker.debounce("A", "job 2")

        expect(Sidekiq::ScheduledSet.new.size).to eq(2)

        groups = Sidekiq::ScheduledSet.new.to_a.sort_by { |g| g.at.to_i }

        expect(groups[0].args[0]).to eq([["A", "job 1"]])
        expect(groups[0].at.to_i).to be((time_start + 5 * 60).to_i)

        expect(groups[1].args[0]).to eq([["A", "job 2"]])
        expect(groups[1].at.to_i).to be((time_start + 11 * 60).to_i)
      end
    end
  end

  context "two types of tasks" do
    context "A task, 3 minutes break, A and B tasks, 3 minutes break, B task, 6 minutes break, B task" do
      it "executes two A tasks after 8 minuts, two B tasks after 11 minutes, last B task after 17 minutes" do
        TestWorker.debounce("A", "job 1")
        Timecop.freeze(time_start + 3 * 60)
        TestWorker.debounce("A", "job 2")
        TestWorker.debounce("B", "job 3")
        Timecop.freeze(time_start + 3 * 60 + 3 * 60)
        TestWorker.debounce("B", "job 4")
        Timecop.freeze(time_start + 3 * 60 + 3 * 60 + 6 * 60)
        TestWorker.debounce("B", "job 5")

        expect(Sidekiq::ScheduledSet.new.size).to eq(3)

        groups = Sidekiq::ScheduledSet.new.to_a.sort_by { |g| g.at.to_i }

        expect(groups[0].args[0]).to eq([["A", "job 1"], ["A", "job 2"]])
        expect(groups[0].at.to_i).to be((time_start + 8 * 60).to_i)

        expect(groups[1].args[0]).to eq([["B", "job 3"], ["B", "job 4"]])
        expect(groups[1].at.to_i).to be((time_start + 11 * 60).to_i)

        expect(groups[2].args[0]).to eq([["B", "job 5"]])
        expect(groups[2].at.to_i).to be((time_start + 17 * 60).to_i)
      end
    end
  end
end
