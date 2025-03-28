# frozen_string_literal: true

require "spec_helper"
require_relative "../../support/context"
require_relative "../../support/test_workers"

describe "Web extension" do
  include Rack::Test::Methods

  include_context "sidekiq"

  let(:app) do
    Rack::Builder.new do
      use Rack::Session::Pool
      run Sidekiq::Web
    end
  end
  let(:job) { described_class.new("debounce/v3/TestWorker/1", 1715472000) }

  before do
    Sidekiq.redis do |conn|
      conn.zadd(Sidekiq::Debouncer::SET, 1715472000, "debounce/v3/TestWorker/1")
      conn.zadd("debounce/v3/TestWorker/1", 1715472000, "xxxx-[1,2]")
      conn.zadd("debounce/v3/TestWorker/1", 1715473000, "xxxx-[3,4]")
    end
  end

  describe "GET /debounces" do
    it "returns a list of debounces" do
      get "/debounces"

      expect(last_response.body).to include("debounce/v3/TestWorker/1")
      expect(last_response.body).to include("2024-05-12 00:00:00 UTC")
    end
  end

  describe "GET /debounces/:base64_key" do
    it "renders the debounce details" do
      get "/debounces/#{Base64.urlsafe_encode64("debounce/v3/TestWorker/1")}"

      expect(last_response.body).to include("TestWorker")
      expect(last_response.body).to include("sample_queue")
      expect(last_response.body).to include("2024-05-12 00:00:00 UTC")
      expect(last_response.body).to include("[1, 2], [3, 4]")
    end
  end
end
