local set = KEYS[1]
local debounce_key = KEYS[2]

local job = ARGV[1]
local time = ARGV[2]
local ttl = ARGV[3]

local existing_debounce = redis.call("GET", debounce_key)

if existing_debounce then
    redis.call("DEL", debounce_key)
    -- skip if job wasn't found in schedule set
    if redis.call("ZREM", set, existing_debounce) > 0 then
        local new_args = cjson.decode(job)['args'][1]
        local new_job = cjson.decode(existing_debounce)
        table.insert(new_job['args'], new_args)
        job = cjson.encode(new_job)
    end
end

redis.call("SET", debounce_key, job, "EX", ttl)
redis.call("ZADD", set, time, job)
