--[[----------------------------------------------------------------------------

  MessagePack encoder / decoder written in pure Lua 5.3
  written by Sebastian Steinhauer <s.steinhauer@yahoo.de>

  This is free and unencumbered software released into the public domain.

  Anyone is free to copy, modify, publish, use, compile, sell, or
  distribute this software, either in source code form or as a compiled
  binary, for any purpose, commercial or non-commercial, and by any
  means.

  In jurisdictions that recognize copyright laws, the author or authors
  of this software dedicate any and all copyright interest in the
  software to the public domain. We make this dedication for the benefit
  of the public at large and to the detriment of our heirs and
  successors. We intend this dedication to be an overt act of
  relinquishment in perpetuity of all present and future rights to this
  software under copyright law.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
  IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
  OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
  ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
  OTHER DEALINGS IN THE SOFTWARE.

  For more information, please refer to <http://unlicense.org/>

--]]----------------------------------------------------------------------------
local msgpack = {
  _AUTHOR = 'Sebastian Steinhauer <s.steinhauer@yahoo.de>',
  _VERSION = '0.2.1',

  config = {
    single_precision = false,   -- use 32-bit floats or 64-bit floats
    binary_strings = false,     -- encode Lua strings a binary data or string data
  },
}


--[[----------------------------------------------------------------------------
      DECODING
--]]----------------------------------------------------------------------------
local decoder_table -- forward reference

local function unpack(ctx, fmt)
  local value, position = fmt:unpack(ctx.input, ctx.position)
  ctx.position = position
  return value
end

local function decode_next(ctx)
  return decoder_table[unpack(ctx, '>B')](ctx)
end

local function decode_array(ctx, length)
  local new = {}
  for i = 1, length do
    new[i] = decode_next(ctx)
  end
  return new
end

local function decode_map(ctx, length)
  local new = {}
  for i = 1, length do
    local k = decode_next(ctx)
    local v = decode_next(ctx)
    new[k] = v
  end
  return new
end

--[[ Decoder Table ]]-----------------------------------------------------------
decoder_table = {
  [0xc0] = function() return nil end,
  [0xc2] = function() return false end,
  [0xc3] = function() return true end,
  [0xc4] = function(ctx) return unpack(ctx, '>s1') end,
  [0xc5] = function(ctx) return unpack(ctx, '>s2') end,
  [0xc6] = function(ctx) return unpack(ctx, '>s4') end,
  [0xca] = function(ctx) return unpack(ctx, '>f') end,
  [0xcb] = function(ctx) return unpack(ctx, '>d') end,
  [0xcc] = function(ctx) return unpack(ctx, '>I1') end,
  [0xcd] = function(ctx) return unpack(ctx, '>I2') end,
  [0xce] = function(ctx) return unpack(ctx, '>I4') end,
  [0xcf] = function(ctx) return unpack(ctx, '>I8') end,
  [0xd0] = function(ctx) return unpack(ctx, '>i1') end,
  [0xd1] = function(ctx) return unpack(ctx, '>i2') end,
  [0xd2] = function(ctx) return unpack(ctx, '>i4') end,
  [0xd3] = function(ctx) return unpack(ctx, '>i8') end,
  [0xd9] = function(ctx) return unpack(ctx, '>s1') end,
  [0xda] = function(ctx) return unpack(ctx, '>s2') end,
  [0xdb] = function(ctx) return unpack(ctx, '>s4') end,
  [0xdc] = function(ctx) return decode_array(ctx, unpack(ctx, '>I2')) end,
  [0xdd] = function(ctx) return decode_array(ctx, unpack(ctx, '>I4')) end,
  [0xde] = function(ctx) return decode_map(ctx, unpack(ctx, '>I2')) end,
  [0xdf] = function(ctx) return decode_map(ctx, unpack(ctx, '>I4')) end,
}

-- add single byte integers
for i = 0x00, 0x7f do
  decoder_table[i] = function() return i end
end
for i = 0xe0, 0xff do
  decoder_table[i] = function() return -32 + i - 0xe0 end
end

-- add fixed maps
for i = 0x80, 0x8f do
  decoder_table[i] = function(ctx) return decode_map(ctx, i - 0x80) end
end

-- add fixed arrays
for i = 0x90, 0x9f do
  decoder_table[i] = function(ctx) return decode_array(ctx, i - 0x90) end
end

-- add fixed strings
for i = 0xa0, 0xbf do
  local format = string.format('>c%d', i - 0xa0)
  decoder_table[i] = function(ctx) return unpack(ctx, format) end
end


--[[----------------------------------------------------------------------------
      ENCODING
--]]----------------------------------------------------------------------------
local encoder_table -- forward reference

local function encode_data(data)
  return encoder_table[type(data)](data)
end

local function check_array(data) -- simple function to verify a table is a proper array
  local expected = 1
  for k, v in pairs(data) do
    if k ~= expected then return false end
    expected = expected + 1
  end
  return true
end

--[[ Encoder Table ]]-----------------------------------------------------------
encoder_table = {
  ['nil'] = function()
    return ('>B'):pack(0xc0)
  end,

  boolean = function(data)
    return ('>B'):pack(data and 0xc3 or 0xc2)
  end,

  string = function(data)
    local length = #data
    if msgpack.config.binary_strings then
      if length <= 0xff then
        return ('>B s1'):pack(0xc4, data)
      elseif length <= 0xffff then
        return ('>B s2'):pack(0xc5, data)
      else
        return ('>B s4'):pack(0xc6, data)
      end
    else
      if length < 32 then
        return ('>B'):pack(0xa0 + length) .. data
      elseif length <= 0xff then
        return ('>B s1'):pack(0xd9, data)
      elseif length <= 0xffff then
        return ('>B s2'):pack(0xda, data)
      else
        return ('>B s4'):pack(0xdb, data)
      end
    end
  end,

  number = function(data)
    if math.type(data) == 'integer' then
      if data >= 0 then
        if data <= 0x7f then
          return ('>B'):pack(data)
        elseif data <= 0xff then
          return ('>B I1'):pack(0xcc, data)
        elseif data <= 0xffff then
          return ('>B I2'):pack(0xcd, data)
        elseif data <= 0xffffffff then
          return ('>B I4'):pack(0xce, data)
        else
          return ('>B I8'):pack(0xcf, data)
        end
      else
        if data >= -32 then
          return ('>B'):pack(0xe0 + data + 32)
        elseif data >= -127 then
          return ('>B i1'):pack(0xd0, data)
        elseif data >= -32767 then
          return ('>B i2'):pack(0xd1, data)
        elseif data >= -2147483647 then
          return ('>B i4'):pack(0xd2, data)
        else
          return ('>B i8'):pack(0xd3, data)
        end
      end
    else
      if msgpack.config.single_precision then
        return ('>B f'):pack(0xca, data)
      else
        return ('>B d'):pack(0xcb, data)
      end
    end
  end,

  table = function(data)
    if check_array(data) then
      local elements = {}
      for i, v in pairs(data) do
        elements[i] = encode_data(v)
      end

      local length = #elements
      if length <= 0xf then
        return ('>B'):pack(0x90 + length) .. table.concat(elements)
      elseif length <= 0xffff then
        return ('>B I2'):pack(0xdc, length) .. table.concat(elements)
      else
        return ('>B I4'):pack(0xdd, length) .. table.concat(elements)
      end
    else
      local elements = {}
      for k, v in pairs(data) do
        elements[#elements + 1] = encode_data(k)
        elements[#elements + 1] = encode_data(v)
      end

      local length = #elements // 2
      if length <= 0xf then
        return ('>B'):pack(0x80 + length) .. table.concat(elements)
      elseif length <= 0xffff then
        return ('>B I2'):pack(0xde, length) .. table.concat(elements)
      else
        return ('>B I4'):pack(0xdf, length) .. table.concat(elements)
      end
    end
  end,
}


--[[----------------------------------------------------------------------------
      PUBLIC API
--]]----------------------------------------------------------------------------
function msgpack.encode(data)
  local ok, result = pcall(encode_data, data)
  if ok then
    return result
  else
    return nil, 'cannot encode data to MessagePack'
  end
end

function msgpack.decode(input, position)
  local ctx = { input = input, position = position or 1 }
  local ok, result = pcall(decode_next, ctx)
  if ok then
    return result, ctx.position
  else
    print('E', result)
    return nil, 'cannot decode MessagePack'
  end
end

return msgpack
--[[----------------------------------------------------------------------------
--]]----------------------------------------------------------------------------
