# frozen_string_literal: true

module Sidekiq
  module Debouncer
    class Enq < ::Sidekiq::Scheduled::Enq
      extend LuaCommands

      SET = 'debouncer'
      LUA_ZPOPBYSCORE_WITHSCORE = File.read(File.expand_path("../lua/zpopbyscore_withscore.lua", __FILE__))
      LUA_ZPOPBYSCORE_MULTI = File.read(File.expand_path("../lua/zpopbyscore_multi.lua", __FILE__))

      define_lua_command(:zpopbyscore_withscore, LUA_ZPOPBYSCORE_WITHSCORE)
      define_lua_command(:zpopbyscore_multi, LUA_ZPOPBYSCORE_MULTI)

      def enqueue_jobs
        redis do |conn|
          while !@done && (job, score = zpopbyscore_withscore(conn, keys: [SET], argv: [Time.now.to_f.to_s]))
            job_args = zpopbyscore_multi(conn, keys: [job], argv: [score])

            final_args = job_args.map { |elem| Sidekiq.load_json(elem.split("-", 2)[1]) }
            job_class = job.split("/")[1]
            klass = Object.const_get(job_class)

            @client.push({"args" => final_args, "class" => klass, "debounce_key" => job})

            logger.debug { "enqueued #{SET}: #{job}" }
          end
        end
      end
    end
  end
end
