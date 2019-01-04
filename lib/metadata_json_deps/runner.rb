require 'json'

module MetadataJsonDeps
  class Runner
    def initialize(filenames, updated_module, updated_module_version, verbose)
      @filenames = filenames
      @updated_module = updated_module
      @updated_module_version = updated_module_version
      @verbose = verbose
      @forge = MetadataJsonDeps::ForgeVersions.new
    end

    def run
      @updated_module = @updated_module.sub('-', '/')
      @filenames.each do |filename|
        puts "Checking #{filename}"
        checker = MetadataJsonDeps::MetadataChecker.new(JSON.parse(File.read(filename)), @forge, @updated_module, @updated_module_version)
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

    def self.run(filenames, module_name, new_version, verbose = false)
      self.new(filenames, module_name, new_version, verbose).run
    end
  end
end
