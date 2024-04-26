local set = KEYS[1]
local debounce_key = KEYS[2]

local args = ARGV[1]
local time = ARGV[2]
local ttl = ARGV[3]

redis.call("ZADD", set, time, debounce_key)
redis.call("XADD", debounce_key, time .. "-*", "args", args)
redis.call("EXPIRE", debounce_key, ttl)
