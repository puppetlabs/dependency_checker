require 'metadata_json_deps'

describe 'compare_dependencies' do
  managed_modules = File.join(File.expand_path(File.dirname(File.dirname(__FILE__))), 'fixtures/managed_modules.yaml')
  module_name = 'puppetlabs-stdlib'
  version = '10.0.0'
  verbose = false
  use_slack = false
  logs_file = File.join(File.expand_path(File.dirname(File.dirname(__FILE__))), 'fixtures/logs.log')

  after :each do
    FileUtils.rm(logs_file) if File.exist?(logs_file)
  end

  context 'check compare_dependencies task with valid arguments' do
    it 'is expected to run without errors when all arguments are valid' do
      expect { MetadataJsonDeps::Runner.run(managed_modules, module_name, version, verbose, use_slack, logs_file) }.not_to raise_error
      expect(File.exist?(logs_file)).to be true
    end
  end

  context 'compare_dependencies task with mandatory arguments: managed_modules, module_name, version, verbose' do
    it 'is expected to run without error when all mandatory arguments are valid' do
      expect { MetadataJsonDeps::Runner.run(managed_modules, module_name, version, verbose) }.not_to raise_error
      expect(File.exist?(logs_file)).to be false
    end
  end

  context 'compare_dependencies task with invalid arguments' do
    it 'is expected to raise an error when managed_modules is not found' do
      error_message = "File 'invalid path' is empty/does not exist"
      expect { MetadataJsonDeps::Runner.run('invalid path', 'puppetlabs-stdlib', '1.0.0', verbose) }.to raise_error(RuntimeError, error_message)
    end

    it 'is expected to raise an error when module name could not be found in the Forge' do
      error_message = '*Error:* Could not find *invalid_name* on Puppet Forge! Ensure updated_module argument is valid.'
      expect { MetadataJsonDeps::Runner.run(managed_modules, 'invalid_name', '1.0.0', verbose) }.to raise_error(RuntimeError, error_message)
    end

    it 'is expected to raise an error when version has an invalid syntax' do
      error_message = '*Error:* Verify semantic versioning syntax *1.00* of updated_module_version argument.'
      expect { MetadataJsonDeps::Runner.run(managed_modules, 'puppetlabs-stdlib', '1.00', verbose) }.to raise_error(RuntimeError, error_message)
    end
  end
end
