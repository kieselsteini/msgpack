# MessagePack for Lua 5.3

## Overview

This is a pure Lua implementation for encoding/decoding MessagePack (https://msgpack.org).

Please report any bugs you encounter!

Features:
- written in pure Lua 5.3 (using ```string.pack()``` / ```string.unpack()```)
- can distinguish between integer / float numbers
- can distinguish between UTF-8 strings and binary data
- public domain license (http://unlicense.org)
- pretty fast decoding

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

The encoder will encode Lua strings as MessagePack strings when they are properly UTF-8 encoded otherwise they will become MessagePack binary objects.

There is also a check if a Lua number can be lossless encoded as a 32-bit float.

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
