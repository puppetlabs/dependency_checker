# dependency-checker

The dependency-checker tool validates dependencies in Puppet modules against the
latest published versions on the [Puppet Forge](https://forge.puppet.com/). This
means that it will ensure that a module supports the latest version of all the
dependencies it declares.

## Installation

Install via RubyGems:

    $ gem install dependency_checker

Or add it to your `Gemfile`:

    gem 'dependency_checker'

## Usage

Run against a single Puppet module `metadata.json` file to ensure that the module
supports the current versions of all the dependencies it declares:

    $ dependency-checker /path/to/metadata.json

Run against a whole list of modules to ensure that each module supports the current
version of the dependencies it declares. You can use a YAML or JSON file containing
an array of modules (`namespace-module`). The file can be local or remote:

    $ dependency-checker managed_modules.yaml
    $ dependency-checker https://my.webserver.com/path/to/managed_modules.json

Run against many modules on your filesystem with a path wildcard:

    $ dependency-checker modules/*/metadata.json

Run against all modules in an author's Forge namespace, optionally filtering to
only supported/approved/partner endorsements:

    $ dependency-checker --namespace puppetlabs
    $ dependency-checker --namespace puppetlabs --supported
    $ dependency-checker --namespace puppet --approved

Run it inside a module or group of modules during a pre-release to determine the
effect of version bumps in the `metadata.json` file(s):

    $ dependency-checker -c
    $ dependency-checker -c ../*/metadata.json

Or you can supply an override value directly:

    $ dependency-checker ../*/metadata.json -o puppetlabs/stdlib,10.0.0

The tool defaults to validating all modules supported by the Puppet CAT team if
no module specification arguments are provided.

The following optional parameters are available:

```text
Usage: dependency-checker [options]
    -o, --override module,version    Forge name of module and semantic version to override
    -c, --current                    Extract override version from metadata.json inside current working directory
    -n, --namespace namespace        Check all modules in a given namespace (filter with endorsements).
        --endorsement endorsement    Filter a namespace search by endorsement (supported/approved/partner).
        --es, --supported            Shorthand for `--endorsement supported`
        --ea, --approved             Shorthand for `--endorsement approved`
        --ep, --partner              Shorthand for `--endorsement partner`
    -v, --[no-]verbose               Run verbosely
    -h, --help                       Display help
```

The `-o` and `-c` arguments are exclusive, as are the endorsement filtering options.

### Testing with dependency-checker as a Rake task

You can also integrate `dependency-checker` checks into your tests using a Rake task:

```ruby
require 'dependency_checker'

desc 'Run dependency-checker'
task :metadata_deps do
  files = FileList['modules/*/metadata.json']
  runner = DependencyChecker::Runner.new
  runner.resolve_from_files(files)
  runner.run
end
```
## License

This codebase is licensed under Apache 2.0. However, the open source dependencies included in this codebase might be subject to other software licenses such as AGPL, GPL2.0, and MIT.
