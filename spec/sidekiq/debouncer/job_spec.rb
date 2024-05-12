# frozen_string_literal: true

require "spec_helper"
require_relative "../../support/context"
require_relative "../../support/test_workers"

describe Sidekiq::Debouncer::Job do
  include_context "sidekiq"

  let(:job) { described_class.new("debounce/v3/TestWorker/1", 1715472000) }

  before do
    Sidekiq.redis do |conn|
      conn.zadd("debounce/v3/TestWorker/1", 1715472000, "xxxx-[1,2]")
      conn.zadd("debounce/v3/TestWorker/1", 1715473000, "xxxx-[3,4]")
    end
  end

  describe "#at" do
    it "returns the time the job is scheduled to run" do
      expect(job.at).to eq(Time.new(2024, 5, 12, 0, 0, 0, 0))
    end
  end

  describe "#args" do
    it "returns all args from redis" do
      expect(job.args).to eq([[1, 2], [3, 4]])
    end
  end

  describe "#queue" do
    it "returns correct queue" do
      expect(job.queue).to eq("sample_queue")
    end
  end

  describe "#klass" do
    it "returns correct class as string" do
      expect(job.klass).to eq("TestWorker")
    end
  end
end
