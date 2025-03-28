# frozen_string_literal: true

require "spec_helper"
require_relative "../../../support/context"

describe "zpopbyscore_withscore" do
  include_context "sidekiq"

  before do
    Sidekiq.redis do |connection|
      connection.call("ZADD", "sample_set", "11111111", "key1")
      connection.call("ZADD", "sample_set", "11111112", "key2")
    end
  end

  let(:fake_class) do
    Class.new do
      extend Sidekiq::Debouncer::LuaCommands

      script = File.read(File.expand_path("../../../../../lib/sidekiq/debouncer/lua/zpopbyscore_withscore.lua", __FILE__))

      define_lua_command(:zpopbyscore_withscore, script)
    end
  end

  it "pops element from sorted set and returns it with score" do
    result = Sidekiq.redis do |connection|
      fake_class.new.zpopbyscore_withscore(connection, ["sample_set"], ["11111112"])
    end
    expect(result[0]).to eq("key1")
    expect(result[1].to_s).to eq("11111111")

    Sidekiq.redis do |connection|
      expect(connection.call("ZCARD", "sample_set")).to eq(1)
    end
  end
end
