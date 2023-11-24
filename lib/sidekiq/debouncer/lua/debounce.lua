local set = KEYS[1]
local debounce_key = KEYS[2]

local job = ARGV[1]
local time = ARGV[2]
local ttl = ARGV[3]
local max_time = ARGV[4]
local max = ARGV[5]

local existing_debounce = redis.call("GET", debounce_key)
local set_key = true

if existing_debounce then
    redis.call("DEL", debounce_key)
    local existing_job = cjson.decode(existing_debounce)

    -- skip if max_time reached
    if max_time == '' or (tonumber(existing_job['created_at']) + tonumber(max_time) > tonumber(time)) then
        -- skip if job wasn't found in schedule set
        if redis.call("ZREM", set, existing_debounce) > 0 then
            local new_args = cjson.decode(job)['args'][1]
            table.insert(existing_job['args'], new_args)

            -- if max is reached put job into schedule set with time = 0 (which should result in enqueueing it almost immediately)
            -- and don't set debounce_key (to avoid another debounce if another job is enqueued in the meantime)
            if (not (max == '')) and (table.getn(existing_job['args']) >= tonumber(max)) then
                time = 0
                set_key = false
            end

            job = cjson.encode(existing_job)
        end
    end
end

if set_key then
    redis.call("SET", debounce_key, job, "EX", ttl)
end
redis.call("ZADD", set, time, job)
