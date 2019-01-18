require 'metadata_json_deps'

describe 'compare_dependencies' do
  managed_modules = File.join(File.expand_path(File.dirname(File.dirname(__FILE__))), 'spec/managed_modules.yaml')
  module_name="puppetlabs-stdlib"
  version = "10.0.0"
  verbose = false
  use_slack = false
  logs_file = File.join(File.expand_path(File.dirname(File.dirname(__FILE__))), 'spec/logs.log')

  after :each do
    FileUtils.rm(logs_file) if File.exists?(logs_file)
  end

  describe 'check task compare_dependencies with valid arguments' do
    before :each do
      MetadataJsonDeps::Runner.run(managed_modules, module_name, version, verbose, use_slack, logs_file)
      while File.exists?(logs_file) == false
        puts "sleep"*10
        sleep(5)
      end
    end

    it 'is expected to not raise an error when all arguments are valid' do
      expect { MetadataJsonDeps::Runner.run(managed_modules, module_name, version, verbose, use_slack, logs_file) }.not_to raise_error
    end

    it 'is expected to create logs file' do
      expect(File.exist?(logs_file)).to be true
    end
  end

  describe 'check task with mandatory arguments: managed_modules, module_name, version, verbose' do
    before :each do
      MetadataJsonDeps::Runner.run(managed_modules, module_name, version, verbose)
    end

    describe 'compare_dependencies with valid arguments' do
      it 'is expected to not raise an error when all arguments are valid' do
        expect { MetadataJsonDeps::Runner.run(managed_modules, module_name, version, verbose) }.not_to raise_error
      end

      it 'is expected to create logs file' do
        expect(File.exist?(logs_file)).to be false
      end
    end
  end

  describe 'compare_dependencies with invalid arguments' do
    managed_modules = File.join(File.expand_path(File.dirname(File.dirname(__FILE__))), 'spec/managed_modules.yaml')
    verbose = false

    it 'is expected to raise an error when managed_modules is not found' do
      expect { MetadataJsonDeps::Runner.run('invalid path', 'puppetlabs-stdlib', '1.0.0', verbose) }.to raise_error
    end

    it 'is expected to not raise an error when module name could not be found in the Forge' do
      expect { MetadataJsonDeps::Runner.run(managed_modules, 'invalid_name', '1.0.0', verbose) }.to raise_error
    end

    it 'is expected to not raise an error when version has an invalid syntax' do
      expect { MetadataJsonDeps::Runner.run(managed_modules, 'puppetlabs-stdlib', '1.00', verbose) }.to raise_error
    end
  end
end

# describe 'check content' do
#   it 'is expected to send logs to file' do
#     logs_file = File.join(File.expand_path(File.dirname(File.dirname(__FILE__))), 'spec/logs.log')
#     expect(File.read(logs_file)). to include 'Comparing modules against'
#   end
# end