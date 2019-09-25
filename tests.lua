--[[----------------------------------------------------------------------------

		MessagePack Tests

--]]----------------------------------------------------------------------------
local msgpack = require('msgpack')

-- do very quick encode / decode tests
do
	local bytes = assert(msgpack.encode(1, -5, math.pi, 'Test!', true, false, { a = 1, b = 2 }))
	local a, b, c, d, e, f, g = assert(msgpack.decode(bytes))
	assert(a == 1)
	assert(b == -5)
	assert(c == math.pi)
	assert(d == 'Test!')
	assert(e == true)
	assert(f == false)
	assert(type(g) == 'table')
	assert(g.a == 1)
	assert(g.b == 2)
end

-- checks for online decoder
do
	local bytes = assert(msgpack.encode({
		array = { 1, 2, 3, 4, 5, 6 },
		foo = 'bar',
		a_true_value = true,
		a_false_value = false,
	}))
	local hex = {}; for i = 1, #bytes do hex[i] = string.format('%02X', string.byte(bytes, i)) end
	print(table.concat(hex, ' '))
end

-- test positive fixint
for i = 0, 0x7f do
	local bytes = assert(msgpack.encode(i))
	assert(#bytes == 1, 'invalid size for positive fixint')
	local decoded = assert(msgpack.decode(bytes))
	assert(decoded == i, 'returned wrong positive fixint')
end

-- test negative fixint
for i = -32, -1, -1 do
	local bytes = assert(msgpack.encode(i))
	assert(#bytes == 1, 'invalid size for negative fixint')
	local decoded = assert(msgpack.decode(bytes))
	assert(decoded == i, 'returned wrong negative fixint')
end

-- test nil
do
	local bytes = assert(msgpack.encode(nil))
	assert(#bytes == 1, 'invalid size for nil')
	assert(string.byte(bytes) == 0xc0, 'invalid code for nil')
	local decoded = msgpack.decode(bytes) -- no assert here because it's nil :)
	assert(decoded == nil)
end

-- test false
do
	local bytes = assert(msgpack.encode(false))
	assert(#bytes == 1, 'invalid size for false')
	assert(string.byte(bytes) == 0xc2, 'invalid code for false')
	local decoded = msgpack.decode(bytes) -- no assert here because it's false :)
	assert(decoded == false)
end

-- test true
do
	local bytes = assert(msgpack.encode(true))
	assert(#bytes == 1, 'invalid size for true')
	assert(string.byte(bytes) == 0xc3, 'invalid code for true')
	local decoded = assert(msgpack.decode(bytes))
	assert(decoded == true)
end

-- test unsigned integer
local function test_uint8(value)
	local bytes = assert(msgpack.encode(value))
	assert(#bytes == 2, 'invalid size for uint8')
	assert(string.byte(bytes) == 0xcc, 'invalid code for uint8')
	local decoded = assert(msgpack.decode(bytes))
	assert(decoded == value)
end

local function test_uint16(value)
	local bytes = assert(msgpack.encode(value))
	assert(#bytes == 3, 'invalid size for uint16')
	assert(string.byte(bytes) == 0xcd, 'invalid code for uint16')
	local decoded = assert(msgpack.decode(bytes))
	assert(decoded == value)
end

local function test_uint32(value)
	local bytes = assert(msgpack.encode(value))
	assert(#bytes == 5, 'invalid size for uint32')
	assert(string.byte(bytes) == 0xce, 'invalid code for uint32')
	local decoded = assert(msgpack.decode(bytes))
	assert(decoded == value)
end

local function test_uint64(value)
	local bytes = assert(msgpack.encode(value))
	assert(#bytes == 9, 'invalid size for uint64')
	assert(string.byte(bytes) == 0xcf, 'invalid code for uint64')
	local decoded = assert(msgpack.decode(bytes))
	assert(decoded == value)
end

test_uint8(128)
test_uint8(255)
test_uint16(256)
test_uint16(65535)
test_uint32(65536)
test_uint32(4294967295)
test_uint64(4294967296)
test_uint64(4294967296 * 10)

-- test signed integer
local function test_int8(value)
	local bytes = assert(msgpack.encode(value))
	assert(#bytes == 2, 'invalid size for int8')
	assert(string.byte(bytes) == 0xd0, 'invalid code for int8')
	local decoded = assert(msgpack.decode(bytes))
	assert(decoded == value)
end

local function test_int16(value)
	local bytes = assert(msgpack.encode(value))
	assert(#bytes == 3, 'invalid size for int16')
	assert(string.byte(bytes) == 0xd1, 'invalid code for int16')
	local decoded = assert(msgpack.decode(bytes))
	assert(decoded == value)
end

local function test_int32(value)
	local bytes = assert(msgpack.encode(value))
	assert(#bytes == 5, 'invalid size for int32')
	assert(string.byte(bytes) == 0xd2, 'invalid code for int32')
	local decoded = assert(msgpack.decode(bytes))
	assert(decoded == value)
end

local function test_int64(value)
	local bytes = assert(msgpack.encode(value))
	assert(#bytes == 9, 'invalid size for int64')
	assert(string.byte(bytes) == 0xd3, 'invalid code for int64')
	local decoded = assert(msgpack.decode(bytes))
	assert(decoded == value)
end

test_int8(-33)
test_int8(-128)
test_int16(-129)
test_int16(-32768)
test_int32(-32769)
test_int32(-2147483648)
test_int64(-2147483649)
test_int64(-2147483649 * 10)

-- test floating points
local function test_float(value)
	local bytes = assert(msgpack.encode(value))
	assert(#bytes == 5, 'invalid size for float')
	assert(string.byte(bytes) == 0xca, 'invalid code for float')
	local decoded = assert(msgpack.decode(bytes))
	assert(decoded == value)
end

local function test_double(value)
	local bytes = assert(msgpack.encode(value))
	assert(#bytes == 9, 'invalid size for double')
	assert(string.byte(bytes) == 0xcb, 'invalid code for double')
	local decoded = assert(msgpack.decode(bytes))
	assert(decoded == value)
end

test_float(1.0)
test_float(2.5)
test_double(math.pi)

-- test fixarray
for i = 0, 15 do
	local array = {}; for j = 1, i do array[j] = j end -- prepare test array
	local bytes = assert(msgpack.encode(array))
	assert(string.byte(bytes) == 0x90 + i)
	array = assert(msgpack.decode(bytes))
	for j = 1, i do assert(array[j] == j) end
end

-- test fixmap
for i = 1, 15 do -- map with size 0 will be encoded as an array, so we start at 1
	local array = {}; for j = 1, i do array['item_' .. j] = j end -- prepare test array
	local bytes = assert(msgpack.encode(array))
	assert(string.byte(bytes) == 0x80 + i)
	array = assert(msgpack.decode(bytes))
	for j = 1, i do assert(array['item_' .. j] == j) end
end

-- test array 16
do
	local array = {}; for i = 1, 1024 do array[i] = i end -- prepare test array
	local bytes = assert(msgpack.encode(array))
	assert(string.byte(bytes) == 0xdc)
	array = assert(msgpack.decode(bytes))
	for i = 1, 128 do assert(array[i], i) end
end

-- test array 32
do
	local array = {}; for i = 1, 1024 * 128 do array[i] = i end -- prepare test array
	local bytes = assert(msgpack.encode(array))
	assert(string.byte(bytes) == 0xdd)
	array = assert(msgpack.decode(bytes))
	for i = 1, 1024 * 128 do assert(array[i], i) end
end

-- test map 16
do
	local map = {}; for i = 1, 1024 do map['item_' .. i] = i end -- prepare test map
	local bytes = assert(msgpack.encode(map))
	assert(string.byte(bytes) == 0xde)
	map = assert(msgpack.decode(bytes))
	for i = 1, 128 do assert(map['item_' .. i], i) end
end

-- test map 32
do
	local map = {}; for i = 1, 1024 * 128 do map['item_' .. i] = i end -- prepare test map
	local bytes = assert(msgpack.encode(map))
	assert(string.byte(bytes) == 0xdf)
	map = assert(msgpack.decode(bytes))
	for i = 1, 1024 * 128 do assert(map['item_' .. i], i) end
end

-- test the payload from msgpack.org :)
do
	local bytes = assert(msgpack.encode({ compact = true, schema = 0 }))
	local check = { 0x82, 0xa6, 0x73, 0x63, 0x68, 0x65, 0x6d, 0x61, 0x00, 0xa7, 0x63, 0x6f, 0x6d, 0x70, 0x61, 0x63, 0x74, 0xc3 }
	for i = 1, #bytes do assert(string.byte(bytes, i) == check[i]) end
end
