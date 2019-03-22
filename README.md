# dependency-checker

The dependency-checker tool validates dependencies in `metadata.json` files in Puppet modules or YAML files containing arrays of Puppet modules against the latest published versions on the [Puppet Forge](https://forge.puppet.com/).

## Compatibility

dependency-checker is compatible with Ruby versions 2.0.0 and newer.

## Installation

via `gem` command:

    `gem install metadata_json_deps`

via Gemfile:

    `gem 'metadata_json_deps`

## Usage

Run against a single Puppet module metadata.json file

    $ dependency-checker /path/to/metadata.json

You can use a local/remote YAML file containing an array of modules (using syntax `namespace/module`)

    $ dependency-checker managed_modules.yaml

It can also be run verbosely to show valid dependencies:

    $ dependency-checker -v modules/*/metadata.json

You can also run it inside a module during a pre-release to determine the effect of a version bump in the metadata.json:

    $ dependency-checker -c ../*/metadata.json

Or you can supply an override value

    $ dependency-checker ../*/metadata.json -o puppetlabs/stdlib,10.0.0

The following optional parameters are available:
```
    -o, --override module,version    Forge name of module and semantic version to override
    -c, --current                    Extract override version from metadata.json inside current working directory
    -v, --[no-]verbose               Run verbosely
    -h, --help                       Display help
```

If attempting to use both `-o` and `-c`, an error will be thrown as these can only be used exclusively.

### Testing with dependency-checker as a Rake task

You can also integrate `dependency-checker` checks into your tests using a Rake task:

```ruby
require 'dependency_checker'

desc 'Run dependency-checker'
task :metadata_deps do
  files = FileList['modules/*/metadata.json']
  DependencyChecker::Runner.run(files)
end
```
