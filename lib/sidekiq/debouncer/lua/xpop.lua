local key, now = KEYS[1], ARGV[1]
local args = redis.call("xrange", key, "-", now)
-- TODO: check if we can somehow avoid xdel
redis.call("xtrim", key, "MINID", args[#args][1])
redis.call("xdel", key, args[#args][1])
return args
