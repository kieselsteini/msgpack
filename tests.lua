--[[----------------------------------------------------------------------------
      Unit-Tests for my MessagePack implementation
--]]----------------------------------------------------------------------------
local msgpack = require('msgpack')
local encode = msgpack.encode
local decode = msgpack.decode
local decode_one = msgpack.decode_one

--[[----------------------------------------------------------------------------
      ENCODER Tests
--]]----------------------------------------------------------------------------
-- simple values
assert(encode(nil) == '\xc0')
assert(encode(false) == '\xc2')
assert(encode(true) == '\xc3')

-- positive integers
for i = 0, 0x7f do assert(encode(i) == string.char(i)) end
assert(encode(0x80) == ('>B B'):pack(0xcc, 0x80))
assert(encode(0xff) == ('>B B'):pack(0xcc, 0xff))
assert(encode(0x100) == ('>B I2'):pack(0xcd, 0x100))
assert(encode(0xffff) == ('>B I2'):pack(0xcd, 0xffff))
assert(encode(0x10000) == ('> B I4'):pack(0xce, 0x10000))
assert(encode(0xffffffff) == ('>B I4'):pack(0xce, 0xffffffff))
assert(encode(0x100000000) == ('>B I8'):pack(0xcf, 0x100000000))

-- negative integers
for i = -32, -1 do assert(encode(i) == ('>B'):pack(0xe0 + i + 32)) end
assert(encode(-33) == ('>B i1'):pack(0xd0, -33))
assert(encode(-127) == ('>B i1'):pack(0xd0, -127))
assert(encode(-128) == ('>B i2'):pack(0xd1, -128))
assert(encode(-32767) == ('>B i2'):pack(0xd1, -32767))
assert(encode(-32768) == ('>B i4'):pack(0xd2, -32768))
assert(encode(-2147483647) == ('>B i4'):pack(0xd2, -2147483647))
assert(encode(-2147483648) == ('>B i8'):pack(0xd3, -2147483648))

-- 32-bit floats
msgpack.config.single_precision = true
assert(encode(1.0) == ('>B f'):pack(0xca, 1.0))

-- 64-bit floats
msgpack.config.single_precision = false
assert(encode(1.0) == ('>B d'):pack(0xcb, 1.0))
assert(encode(math.pi) == ('>B d'):pack(0xcb, math.pi))

-- strings
msgpack.config.binary_strings = false
for i = 0, 31 do
  local str = ('x'):rep(i)
  assert(encode(str) == ('>B'):pack(0xa0 + i) .. str)
end
assert(encode(('x'):rep(32)) == ('>B s1'):pack(0xd9, ('x'):rep(32)))
assert(encode(('x'):rep(0xff)) == ('>B s1'):pack(0xd9, ('x'):rep(0xff)))
assert(encode(('x'):rep(0x100)) == ('>B s2'):pack(0xda, ('x'):rep(0x100)))
assert(encode(('x'):rep(0xffff)) == ('>B s2'):pack(0xda, ('x'):rep(0xffff)))
assert(encode(('x'):rep(0x10000)) == ('>B s4'):pack(0xdb, ('x'):rep(0x10000)))

-- binary
msgpack.config.binary_strings = true
for i = 0, 31 do
  local str = ('x'):rep(i)
  assert(encode(str) == ('>B s1'):pack(0xc4, str))
end
assert(encode(('x'):rep(32)) == ('>B s1'):pack(0xc4, ('x'):rep(32)))
assert(encode(('x'):rep(0xff)) == ('>B s1'):pack(0xc4, ('x'):rep(0xff)))
assert(encode(('x'):rep(0x100)) == ('>B s2'):pack(0xc5, ('x'):rep(0x100)))
assert(encode(('x'):rep(0xffff)) == ('>B s2'):pack(0xc5, ('x'):rep(0xffff)))
assert(encode(('x'):rep(0x10000)) == ('>B s4'):pack(0xc6, ('x'):rep(0x10000)))

-- arrays
assert(encode({}) == ('>B'):pack(0x90))
assert(encode({1, 2}) == ('>B B B'):pack(0x92, 1, 2))

-- maps
assert(encode({[2] = 1}) == ('>B B B'):pack(0x81, 2, 1))


--[[----------------------------------------------------------------------------
      DECODER Tests
--]]----------------------------------------------------------------------------
-- simple values
assert(decode('\xc0') == nil)
assert(decode('\xc2') == false)
assert(decode('\xc3') == true)

-- positive integers
for i = 0, 0x7f do assert(decode(string.char(i)) == i) end
assert(decode('\xcc\xff') == 0xff)
assert(decode('\xcd\xff\xff') == 0xffff)
assert(decode('\xce\xff\xff\xff\xff') == 0xffffffff)
assert(decode('\xcf\xff\xff\xff\xff\xff\xff\xff\xff') == 0xffffffffffffffff)

-- negative integers
assert(decode('\xff') == -1)
assert(decode('\xe0') == -32)
assert(decode('\xd0\xdf') == -33)
assert(decode('\xd0\x81') == -127)
assert(decode('\xd1\xff\x80') == -128)
assert(decode('\xd1\x80\x01') == -32767)
assert(decode('\xd2\xff\xff\x80\x00') == -32768)
assert(decode('\xd2\x80\x00\x00\x01') == -2147483647)
assert(decode('\xd3\xff\xff\xff\xff\x80\x00\x00\x00') == -2147483648)

-- 64-bit floats
assert(decode('\xcb\x40\x09\x1e\xb8\x51\xeb\x85\x1f') == 3.14)

-- strings
assert(decode('\xa0') == '')
assert(decode('\xa1\x41') == 'A')
assert(decode('\xbf' .. ('A'):rep(31)) == ('A'):rep(31))

-- arrays
assert(#decode('\x90') == 0)

-- multiple decodings and start from different positions
do
  local binary, value, position = '\xcc\xff\xc2\xc3'
  value, position = decode_one(binary, position); assert(value == 255) -- decode 2 bytes
  value, position = decode_one(binary, position); assert(value == false) -- decode 1 byte
  value, position = decode_one(binary, position); assert(value == true) -- decode 1 byte
  assert(position == 5) -- 5th byte would be the next in the "stream"
end

-- decode multiple values
do
  local a, b, c = decode('\xe0\xa1\x41\xc3')
  assert(a == -32)
  assert(b == 'A')
  assert(c == true)
end
