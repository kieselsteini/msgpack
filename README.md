# MessagePack for Lua 5.3

## Overview

This is a pure Lua implementation for encoding/decoding MessagePack (https://msgpack.org).

Please report any bugs you encounter!

Features:
- written in pure Lua 5.3 (using ```string.pack()``` / ```string.unpack()```)
- can distinguish between integer / float numbers
- public domain license (http://unlicense.org)
- pretty fast decoding
- config variables to switch between string/binary and float32/float64 encoding

What's missing:
- extendend types ```fixent```

Example code:
```lua
local msgpack = require('msgpack')

local value = msgpack.decode(binary_msgpack_data) -- decode to Lua value

local binary_data = msgpack.encode(lua_value) -- encode Lua value to MessagePack
```

## API

### msgpack.encode_one(value)
Encodes the given Lua value to a binary MessagePack representation. It will return the binary string on succes or ```nil``` plus an error message if it fails.

Please note that Lua cannot distinguish between UTF-8 strings and binary data. They are just Lua strings. So if you want to encode Lua strings to MessagePack binary data you have to set the config variable.

There is also no way to determine if a Lua number should be encoded as a 32-bit float or 64-bit float. If you want a specific representation, please set the corresponding config variable.

Using 32-bit/64-bit floats to encode Lua numbers:
```lua
msgpack.config.single_precision = true -- encode to 32-bit floats
msgpack.config.single_precision = false -- encode to 64-bit floats
```

Using binary/string type to encode Lua strings:
```lua
msgpack.config.binary_strings = true -- use the MessagePack binary type
msgpack.config.binary_strings = false -- use the MessagePack string type
```

> **NOTE:** The config variables only affect the encoding process

> **NOTE:** Encoding strings as binary also affects string keys in tables

> **NOTE:** Empty Lua tables will be encoded as empty arrays!

### msgpack.encode(...)
Encodes all given values to a binary MessagePack representation. It will return the binary string or ```nil``` plus an error message if it fails.

```lua
local binary = msgpack.encode('Hello', 1024, true, { 2, 3, 4 })
```

### msgpack.decode_one(binary_data[, position])
Decode the given MessagePack binary string to a corresponding Lua value. It will return the decoded Lua value and the position for next byte in stream
or ```nil``` plus an error message if decoding went wrong. You can use the returned position to decode multiple MessagePack values in a stream.

The optional position argument is used to start the decoding at a specific position inside the the binary_data string.

> **NOTE:** Extended types are not supported. Decoding will fail!

> **NOTE:** Binary data will be decoded as Lua strings

> **NOTE:** Arrays will be decoded as Lua tables starting with index 1 (like Lua uses tables as arrays)

> **NOTE:** Values which are ```nil``` will cause the key, value pair to disappear in a Lua table (that's how it works in Lua)

### msgpack.decode(binary_data[, position])
Decode the given MessagePack binary string to one or more Lua values. It will return all decoded Lua values or ```nil``` plus an error message if decoding failed.

```lua
local a, b, c = msgpack.decode(binary)
```

## License
```
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
```
