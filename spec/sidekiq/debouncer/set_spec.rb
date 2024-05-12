# frozen_string_literal: true

require "spec_helper"
require_relative "../../support/context"

describe Sidekiq::Debouncer::Set do
  include_context "sidekiq"

  let(:set) { described_class.new }

  describe "#fetch_by_key" do
    before do
      Sidekiq.redis do |conn|
        conn.zadd(Sidekiq::Debouncer::SET, 1, "key")
      end
    end

    it "returns a Job instance" do
      job = set.fetch_by_key("key")
      expect(job).to be_a(Sidekiq::Debouncer::Job)
      expect(job.key).to eq("key")
      expect(job.score).to eq(1)
    end
  end
end
