# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'dependency_checker/version'

Gem::Specification.new do |s|
  s.name        = 'dependency_checker'
  s.version     = DependencyChecker::VERSION
  s.executables << 'dependency-checker'
  s.licenses    = ['MIT']
  s.summary     = 'Check your Puppet metadata dependencies'
  s.description = <<-DESC
    Verify all your dependencies allow the latest versions on Puppet Forge.
    Based on https://github.com/ekohl/metadata_json_deps
  DESC

  s.authors     = ['Ewoud Kohl van Wijngaarden', 'Puppet']
  s.email       = ['info@puppet.com']
  s.files       = Dir['lib/**/*.rb'] + Dir['bin/*']
  s.extra_rdoc_files = ['README.md']
  s.homepage    = 'https://github.com/puppetlabs/dependency_checker'
  s.metadata    = {
    'source_code_uri' => 'https://github.com/puppetlabs/dependency_checker',
    'rubygems_mfa_required' => 'true'
  }
  s.required_ruby_version = Gem::Requirement.new('>= 2.7.0')

  s.add_runtime_dependency 'parallel'
  s.add_runtime_dependency 'puppet_forge', '>= 2.2', '< 6.0'
  s.add_runtime_dependency 'rake', '~> 13.0'
  s.add_runtime_dependency 'semantic_puppet', '~> 1.0'
end
