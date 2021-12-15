Gem::Specification.new do |s|
  s.name        = 'dependency_checker'
  s.version     = '0.3.0'
  s.executables << 'dependency-checker'
  s.licenses    = ['MIT']
  s.summary     = 'Check your Puppet metadata dependencies'
  s.description = <<-EOF
    Verify all your dependencies allow the latest versions on Puppet Forge.
    Based on https://github.com/ekohl/metadata_json_deps
  EOF
  s.authors     = ['Ewoud Kohl van Wijngaarden', 'Puppet']
  s.email       = ['info@puppet.com']
  s.files       = Dir['lib/**/*.rb'] + Dir['bin/*']
  s.extra_rdoc_files = ['README.md']
  s.homepage    = 'https://github.com/puppetlabs/dependency_checker'
  s.metadata    = {
    'source_code_uri' => 'https://github.com/puppetlabs/dependency_checker'
  }
  s.required_ruby_version = Gem::Requirement.new('>= 2.4.0')

  s.add_runtime_dependency 'parallel'
  s.add_runtime_dependency 'puppet_forge', '>= 2.2', '< 4.0'
  s.add_runtime_dependency 'rake', '~> 13.0'
  s.add_runtime_dependency 'semantic_puppet', '~> 1.0'

  s.add_development_dependency 'codecov'
  s.add_development_dependency 'github_changelog_generator', '~> 1.15'
  s.add_development_dependency 'rspec', '~> 3.9'
  s.add_development_dependency 'rubocop'
  s.add_development_dependency 'simplecov-console'
  s.add_development_dependency 'simplecov'
end
