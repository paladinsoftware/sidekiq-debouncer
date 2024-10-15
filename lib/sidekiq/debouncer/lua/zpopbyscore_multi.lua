local key, now = KEYS[1], ARGV[1]
local jobs = redis.call("ZRANGE", key, "-inf", now, "BYSCORE")
redis.call("ZREMRANGEBYSCORE", key, "-inf", now)

return jobs
