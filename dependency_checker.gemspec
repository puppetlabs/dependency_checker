Gem::Specification.new do |s|
  s.name        = 'dependency_checker'
  s.version     = '0.2.0'
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
  s.required_ruby_version = Gem::Requirement.new('>= 2.0.0')

  s.add_runtime_dependency 'puppet_forge', '~> 2.2'
  s.add_runtime_dependency 'rake', '>= 12.3', '< 14.0'
  s.add_runtime_dependency 'semantic_puppet', '~> 1.0'
  s.add_runtime_dependency 'parallel'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rubocop'
end
