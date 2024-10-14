# frozen_string_literal: true

require "digest/sha1"

module Sidekiq
  module Debouncer
    module LuaCommands
      def define_lua_command(command, script)
        sha = Digest::SHA1.hexdigest(script)
        define_method(command) do |conn, keys, argv|
          retryable = true
          begin
            conn.call("EVALSHA", sha, keys.size, *keys, *argv)
          rescue RedisClient::CommandError => e
            raise if !e.message.start_with?("NOSCRIPT") || !retryable

            # upload script to redis cache and retry
            conn.call("SCRIPT", "LOAD", script)
            retryable = false
            retry
          end
        end
      end
    end
  end
end
