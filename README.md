# metadata-json-deps

The metadata-json-deps tool validates dependencies in `metadata.json` files in Puppet modules or YAML files containing arrays of Puppet modules against the latest published versions on the [Puppet Forge](https://forge.puppet.com/).

## Compatibility

metadata-json-deps is compatible with Ruby versions 2.0.0 and newer.

## Usage

Install the gem by supplying it in your Gemfile:

    $ metadata-json-deps /path/to/metadata.json

You can use a local/remote YAML file containing an array of modules (using syntax `namespace/module`)

    $ metadata-json-deps managed_modules.yaml

It can also be run verbosely to show valid dependencies:

    $ metadata-json-deps -v modules/*/metadata.json

You can also run it inside a module during a pre-release to determine the effect of a version bump in the metadata.json:

    $ metadata-json-deps -c ../*/metadata.json

Or you can supply an override value

    $ metadata-json-deps ../*/metadata.json -o puppetlabs/stdlib,10.0.0

The following optional parameters are available:
```
    -o, --override module,version    Forge name of module and semantic version to override
    -c, --current                    Extract override version from metadata.json inside current working directory
    -v, --[no-]verbose               Run verbosely
    -h, --help                       Display help
```

If attempting to use both `-o` and `-c`, an error will be thrown as these can only be used exclusively.

### Testing with metadata-json-deps as a Rake task

You can also integrate `metadata-json-deps` checks into your tests using a Rake task:

```ruby
require 'metadata_json_deps'

desc 'Run metadata-json-deps'
task :metadata_deps do
  files = FileList['modules/*/metadata.json']
  MetadataJsonDeps::Runner.run(files)
end
```
