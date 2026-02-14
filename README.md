# hana

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Crystal](https://img.shields.io/badge/crystal-%3E%3D1.13.2-black)](https://crystal-lang.org/)

Crystal port of the Ruby gem [hana][3].

Implementation of [JSON Patch][1] (RFC 6902) and [JSON Pointer][2] (RFC 6901).

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     hana:
       github: cyangle/hana.cr
       version: ~> 0.1.1
   ```

2. Run `shards install`

**Requirements:** Crystal >= 1.13.2

## Usage

### JSON Patch

Apply patches to JSON documents. Supports all RFC 6902 operations: `add`, `remove`, `replace`, `move`, `copy`, and `test`.

```crystal
require "hana"

doc = JSON.parse(%({
  "name": "John",
  "age": 30,
  "tags": ["developer"]
}))

# Create patch from JSON string
patch = Hana::Patch.new(%([
  { "op": "replace", "path": "/name", "value": "Jane" },
  { "op": "add", "path": "/email", "value": "jane@example.com" },
  { "op": "remove", "path": "/age" },
  { "op": "add", "path": "/tags/-", "value": "designer" }
]))

result = patch.apply(doc)
puts result.to_json
# {"name":"Jane","tags":["developer","designer"],"email":"jane@example.com"}
```

#### Patch Operations

| Operation | Description | Example |
|-----------|-------------|---------|
| `add` | Add a value | `{"op": "add", "path": "/foo", "value": "bar"}` |
| `remove` | Remove a value | `{"op": "remove", "path": "/foo"}` |
| `replace` | Replace a value | `{"op": "replace", "path": "/foo", "value": "baz"}` |
| `move` | Move a value | `{"op": "move", "from": "/foo", "path": "/bar"}` |
| `copy` | Copy a value | `{"op": "copy", "from": "/foo", "path": "/bar"}` |
| `test` | Test a value matches | `{"op": "test", "path": "/foo", "value": "bar"}` |

#### Creating Patches

```crystal
# From JSON string
patch = Hana::Patch.new(%([{"op": "add", "path": "/foo", "value": "bar"}]))

# From IO
patch = Hana::Patch.new(File.open("patches.json"))

# From Array
ops = [{"op" => JSON::Any.new("add"), "path" => JSON::Any.new("/foo"), "value" => JSON::Any.new("bar")}]
patch = Hana::Patch.new(ops)
```

### JSON Pointer

Evaluate JSON Pointers to extract values from JSON documents.

```crystal
require "hana"

doc = JSON.parse(%({
  "users": [
    {"name": "Alice", "role": "admin"},
    {"name": "Bob", "role": "user"}
  ],
  "config": {
    "debug": true
  }
}))

# Get nested values
pointer = Hana::Pointer.new("/users/0/name")
puts pointer.eval(doc) # "Alice"

pointer = Hana::Pointer.new("/users/1/role")
puts pointer.eval(doc) # "user"

pointer = Hana::Pointer.new("/config/debug")
puts pointer.eval(doc) # true
```

## Development

hana runs tests from [json-patch/json-patch-tests](https://github.com/json-patch/json-patch-tests). Fetch the git submodule by running:

```bash
git submodule init
git submodule update
```

Install dependencies with:

```bash
shards install
```

Then run the tests with:

```bash
crystal spec
```

### Linting

Format code with Crystal's built-in formatter:

```bash
crystal tool format
```

Run static analysis with [Ameba](https://github.com/crystal-ameba/ameba):

```bash
bin/ameba
```

## Contributing

1. Fork it (<https://github.com/cyangle/hana.cr/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Chao Yang](https://github.com/cyangle) - creator and maintainer

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

[1]: https://datatracker.ietf.org/doc/rfc6902/
[2]: http://tools.ietf.org/html/rfc6901
[3]: https://github.com/tenderlove/hana
