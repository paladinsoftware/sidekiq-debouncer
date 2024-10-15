local key, now = KEYS[1], ARGV[1]
local jobs = redis.call("ZRANGE", key, "-inf", now, "BYSCORE", "LIMIT", 0, 1, "WITHSCORES")
if jobs[1] then
    redis.call("ZREM", key, jobs[1])
    return {jobs[1], jobs[2]}
end
