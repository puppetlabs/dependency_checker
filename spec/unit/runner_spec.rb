require 'metadata_json_deps'

describe 'compare_dependencies' do
  managed_modules = File.join(File.expand_path(File.dirname(File.dirname(__FILE__))), 'unit/managed_modules.yaml')
  module_name="puppetlabs-stdlib"
  version = "10.0.0"
  verbose = false
  use_slack = false
  logs_file = File.join(File.expand_path(File.dirname(File.dirname(__FILE__))), 'unit/logs.log')

  after :each do
    FileUtils.rm(logs_file) if File.exists?(logs_file)
  end

  describe 'check task compare_dependencies with valid arguments' do
    it 'is expected to run without errors when all arguments are valid' do
      expect { MetadataJsonDeps::Runner.run(managed_modules, module_name, version, verbose, use_slack, logs_file) }.not_to raise_error
      expect(File.exist?(logs_file)).to be true
    end
  end

  describe 'check task with mandatory arguments: managed_modules, module_name, version, verbose' do
    it 'is expected to run without error when all mandatory arguments are valid' do
      expect { MetadataJsonDeps::Runner.run(managed_modules, module_name, version, verbose) }.not_to raise_error
      expect(File.exist?(logs_file)).to be false
    end
  end

  describe 'compare_dependencies with invalid arguments' do
    it 'is expected to raise an error when an argument is incorrect' do
      expect { MetadataJsonDeps::Runner.run('invalid_path', 'puppetlabs-stdlib', '1.0.0', verbose) }.to raise_error(RuntimeError, "File 'invalid_path' is empty/does not exist")
      expect { MetadataJsonDeps::Runner.run(managed_modules, 'invalid_name', '1.0.0', verbose) }.to raise_error(RuntimeError, "Error: Verify *invalid_name* exists on Puppet Forge! Verify semantic versioning syntax *1.0.0*. \n")
      expect { MetadataJsonDeps::Runner.run(managed_modules, 'puppetlabs-stdlib', '1.00', verbose) }.to raise_error(RuntimeError, "Error: Verify *puppetlabs-stdlib* exists on Puppet Forge! Verify semantic versioning syntax *1.00*. \n")
    end
  end
end