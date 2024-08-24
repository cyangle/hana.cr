# hana

crystal port of ruby gem [hana][3].

Implementation of [JSON Patch][1] and [JSON Pointer][2] RFC.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     hana:
       github: cyangle/hana.cr
       version: ~> 0.1.0
   ```

2. Run `shards install`

## Usage

Example json patches in json:

```json
[
  { "op": "add", "path": "/baz", "value": "qux" }
]
```

```crystal
require "hana"

patch_json = File.read("/file/path/to/json_patches.json")

patch = Hana::Patch.new(patch_json)

doc = JSON.parse(%({"foo":"bar"}))

result = patch.apply(doc)

puts result.to_json # Outputs: {"foo":"bar","baz":"qux"}
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

## Contributing

1. Fork it (<https://github.com/cyangle/hana.cr/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Chao Yang](https://github.com/cyangle) - creator and maintainer

[1]: https://datatracker.ietf.org/doc/rfc6902/
[2]: http://tools.ietf.org/html/rfc6901
[3]: https://github.com/tenderlove/hana
