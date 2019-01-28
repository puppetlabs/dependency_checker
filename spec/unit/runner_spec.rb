require 'metadata_json_deps'

describe 'compare_dependencies' do
  managed_modules_file = File.join(File.expand_path(File.dirname(File.dirname(__FILE__))), 'fixtures/managed_modules.yaml')
  managed_modules_url = 'https://gist.githubusercontent.com/eimlav/6df50eda0b1c57c1ab8c33b64c82c336/raw/managed_modules_test.yaml'
  module_name = 'puppetlabs-stdlib'
  version = '10.0.0'
  verbose = false
  use_slack = false
  logs_file = File.join(File.expand_path(File.dirname(File.dirname(__FILE__))), 'fixtures/logs.log')

  after :each do
    FileUtils.rm(logs_file) if File.exist?(logs_file)
  end

  context 'check compare_dependencies task with valid arguments' do
    it 'is expected to run without errors' do
      expect { MetadataJsonDeps::Runner.run(managed_modules_file, module_name, version, verbose, use_slack, logs_file) }.not_to raise_error
      expect(File.exist?(logs_file)).to be true
    end
  end

  context 'compare_dependencies task with mandatory arguments: managed_modules, module_name, version, verbose' do
    it 'is expected to run without error' do
      expect { MetadataJsonDeps::Runner.run(managed_modules_file, module_name, version, verbose) }.not_to raise_error
      expect(File.exist?(logs_file)).to be false
    end

    it 'is expected to run without error when managed_modules is a valid URL' do
      expect { MetadataJsonDeps::Runner.run(managed_modules_url, module_name, version, verbose) }.not_to raise_error
    end
  end

  context 'compare_dependencies task with invalid arguments' do
    it 'is expected to raise an error when managed_modules is not found' do
      error_message = '*Error:* Ensure *invalid path* is a valid file path or URL'
      expect { MetadataJsonDeps::Runner.run('invalid path', 'puppetlabs-stdlib', '1.0.0', verbose) }.to raise_error(RuntimeError, error_message)
    end

    it 'is expected to raise an error when module name could not be found in the Forge' do
      error_message = '*Error:* Could not find *invalid_name* on Puppet Forge! Ensure updated_module argument is valid.'
      expect { MetadataJsonDeps::Runner.run(managed_modules_file, 'invalid_name', '1.0.0', verbose) }.to raise_error(RuntimeError, error_message)
    end

    it 'is expected to raise an error when version has an invalid syntax' do
      error_message = '*Error:* Verify semantic versioning syntax *1.00* of updated_module_version argument.'
      expect { MetadataJsonDeps::Runner.run(managed_modules_file, 'puppetlabs-stdlib', '1.00', verbose) }.to raise_error(RuntimeError, error_message)
    end
  end
end
