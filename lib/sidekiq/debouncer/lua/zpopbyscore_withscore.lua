local key, now = KEYS[1], ARGV[1]
local jobs = redis.call("zrangebyscore", key, "-inf", now, "withscores", "limit", 0, 1)
if jobs[1] then
    redis.call("zrem", key, jobs[1])
    return {jobs[1], jobs[2]}
end
