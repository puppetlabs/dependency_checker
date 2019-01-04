require 'json'
require 'yaml'

module MetadataJsonDeps
  class Runner
    def initialize(filename, updated_module, updated_module_version, verbose)
      @module_names = return_modules(filename)
      @updated_module = updated_module
      @updated_module_version = updated_module_version
      @verbose = verbose
      @forge = MetadataJsonDeps::ForgeHelper.new
    end

    def run
      @updated_module = @updated_module.sub('-', '/')
      @module_names.each do |module_name|
        puts "Checking #{module_name}"
        metadata = @forge.get_metadata_json(module_name)
        checker = MetadataJsonDeps::MetadataChecker.new(metadata, @forge, @updated_module, @updated_module_version)
        checker.dependencies.each do |dependency, constraint, current, satisfied|
          if satisfied
            if @verbose
              puts "  #{dependency} (#{constraint}) matches #{current}"
            end
          else
            puts "  #{dependency} (#{constraint}) doesn't match #{current}"
          end
        end
      end
    rescue Interrupt
    end

    def return_modules(filename)
      raise "File '#{filename}' is empty/does not exist" if File.size?(filename).nil?
      YAML.safe_load(File.open(filename))
    end

    def self.run(filename, module_name, new_version, verbose = false)
      self.new(filename, module_name, new_version, verbose).run
    end
  end
end
