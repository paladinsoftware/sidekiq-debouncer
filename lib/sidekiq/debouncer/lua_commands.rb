# frozen_string_literal: true

require "digest/sha1"

module Sidekiq
  module Debouncer
    module LuaCommands
      REDIS_ERROR_CLASS = defined?(RedisClient::CommandError) ? RedisClient::CommandError : Redis::CommandError

      def define_lua_command(command, script)
        sha = Digest::SHA1.hexdigest(script)
        define_method(command) do |conn, keys: nil, argv: nil|
          retryable = true
          begin
            conn.call("EVALSHA", sha, keys.size, *keys, *argv)
          rescue REDIS_ERROR_CLASS => e
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
