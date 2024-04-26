# frozen_string_literal: true

require "spec_helper"
require_relative "../../../support/context"

describe "xpop" do
  include_context "sidekiq"

  before do
    Sidekiq.redis do |connection|
      connection.call("XADD", "sample_stream", "11111111-0", "key1", "value1", "key2", "value2")
      connection.call("XADD", "sample_stream", "11111112-0", "key3", "value3")
      connection.call("XADD", "sample_stream", "11111112-1", "key4", "value4")
      connection.call("XADD", "sample_stream", "11111113-0", "key5", "value5")
    end
  end

  let(:fake_class) do
    Class.new do
      extend Sidekiq::Debouncer::LuaCommands

      script = File.read(File.expand_path("../../../../../lib/sidekiq/debouncer/lua/xpop.lua", __FILE__))

      define_lua_command(:xpop, script)
    end
  end

  it "pops elements from stream and returns them" do
    result = Sidekiq.redis do |connection|
      fake_class.new.xpop(connection, keys: ["sample_stream"], argv: ["11111112"])
    end
    expect(result).to eq([["11111111-0", ["key1", "value1", "key2", "value2"]], ["11111112-0", ["key3", "value3"]], ["11111112-1", ["key4", "value4"]]])

    Sidekiq.redis do |connection|
      expect(connection.call("XLEN", "sample_stream")).to eq(1)
    end
  end
end
