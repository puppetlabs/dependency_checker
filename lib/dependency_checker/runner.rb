# frozen_string_literal: true

require 'json'
require 'yaml'
require 'open-uri'
require 'logger'
require 'parallel'

# Main runner for DependencyChecker
module DependencyChecker
  class Runner
    attr_reader :problems

    def initialize(verbose = false, forge_hostname = nil, forge_token = nil)
      @forge   = DependencyChecker::ForgeHelper.new({}, forge_hostname, forge_token)
      @verbose = verbose
    end

    def resolve_from_namespace(namespace, endorsement)
      @modules = @forge.modules_in_namespace(namespace, endorsement)
    end

    def resolve_from_path(path)
      @modules = return_modules(path)
    end

    def resolve_from_files(metadata_files)
      @use_local_files = true
      @modules         = Array(metadata_files) # should already be an array, but just in case
    end

    def override=(override)
      return unless override.is_a? Array

      @updated_module, @updated_module_version = override

      raise '*Error:* Pass an override in the form `--override module,version`' unless override.size == 2
      raise "*Error:* Could not find *#{@updated_module}* on Puppet Forge! Ensure updated_module argument is valid." unless check_module_exists(@updated_module)
      unless SemanticPuppet::Version.valid?(@updated_module_version)
        raise "*Error:* Verify semantic versioning syntax *#{@updated_module_version}* of updated_module_version argument."
      end

      puts "Overriding *#{@updated_module}* version with *#{@updated_module_version}*\n\n"
      puts "The module you are comparing against *#{@updated_module}* is *deprecated*.\n\n" if @forge.check_module_deprecated(@updated_module)
    end

    def run
      puts "_*Starting dependency checks...*_\n\n"

      # Post results of dependency checks
      message = run_dependency_checks
      @problems = message.size
      message = 'All modules have valid dependencies.' if message.empty?

      post(message)
    end

    # Check with forge if a specified module exists
    # @param module_name [String]
    # @return [Boolean] boolean based on whether the module exists or not
    def check_module_exists(module_name)
      @forge.check_module_exists(module_name)
    end

    # Perform dependency checks on modules supplied by @modules
    def run_dependency_checks
      # Cross reference dependencies from managed_modules file with @updated_module and @updated_module_version
      messages = Parallel.map(@modules) do |module_path|
        module_name = @use_local_files ? get_name_from_metadata(module_path) : module_path
        mod_message = "Checking *#{module_path}* dependencies.\n"
        exists_on_forge = true

        # Check module_path is valid
        unless check_module_exists(module_name)
          if @use_local_files
            exists_on_forge = false
          else
            mod_message += "\t*Error:* Could not find *#{module_name}* on Puppet Forge! Ensure the module exists.\n\n"
            next mod_message
          end
        end

        # Fetch module dependencies

        dependencies = @use_local_files ? get_dependencies_from_path(module_path) : get_dependencies(module_name)

        # Post warning if module_path is deprecated
        mod_deprecated = exists_on_forge ? @forge.check_module_deprecated(module_name) : false
        mod_message += "\t*Warning:* *#{module_name}* is *deprecated*.\n" if mod_deprecated

        if dependencies.empty?
          mod_message += "\tNo dependencies listed\n\n"
          next mod_message if @verbose && !mod_deprecated
        end

        # Check each dependency to see if the latest version matchs the current modules' dependency constraints
        all_match = true
        dependencies.each do |dependency, constraint, current, satisfied|
          if satisfied && @verbose
            mod_message += "\t#{dependency} (#{constraint}) *matches* #{current}\n"
          elsif !satisfied
            all_match = false
            mod_message += "\t#{dependency} (#{constraint}) *doesn't match* #{current}\n"
          end

          if @forge.check_module_deprecated(dependency)
            all_match = false
            mod_message += "\t\t*Warning:* *#{dependency}* is *deprecated*.\n"
          end

          found_deprecation = true if @forge.check_module_deprecated(dependency)

          # Post warning if dependency is deprecated
          mod_message += "\tThe dependency module *#{dependency}* is *deprecated*.\n" if found_deprecation
        end

        mod_message += "\tAll dependencies match\n" if all_match
        mod_message += "\n"

        # If @verbose is true, always post message
        # If @verbose is false, only post if all dependencies don't match and/or if a dependency is deprecated
        all_match && !@verbose ? '' : mod_message
      end

      message = ''
      messages.each do |result|
        message += result
      end

      message
    end

    # Get dependencies of a supplied module name to verify if the depedencies are satisfied
    # @param module_name [String] name of module
    # @return [Map] a map of dependencies along with their constraint, current version and whether they satisfy the constraint
    def get_dependencies(module_name)
      module_data = @forge.get_module_data(module_name)
      metadata = module_data.current_release.metadata
      get_dependencies_from_metadata(metadata)
    end

    # Get dependencies of a supplied module from a metadata.json file to verify if the depedencies are satisfied
    # @param metadata_path [String] path to metadata.json
    # @return [Map] a map of dependencies along with their constraint, current version and whether they satisfy the constraint
    def get_dependencies_from_path(metadata_path)
      metadata = JSON.parse(File.read(metadata_path), symbolize_names: true)
      get_dependencies_from_metadata(metadata)
    end

    # Get dependencies of supplied module metadata. Takes module ovveride into account.
    # @param metadata [Hash] module metadata
    # @return [Map] a map of dependencies along with their constraint, current version and whether they satisfy the constraint
    def get_dependencies_from_metadata(metadata)
      checker = DependencyChecker::MetadataChecker.new(metadata, @forge, @updated_module, @updated_module_version)
      checker.check_dependencies
    end

    # Get dependencies of a supplied module from a metadata.json file to verify if the depedencies are satisfied
    # @param metadata_path [String] path to metadata.json
    # @return [Map] a map of dependencies along with their constraint, current version and whether they satisfy the constraint
    def get_name_from_metadata(metadata_path)
      metadata = JSON.parse(File.read(metadata_path), symbolize_names: true)
      metadata[:name]
    end

    # Retrieve the array of module names from the supplied filename/URL
    # @return [Array] an array of module names
    def return_modules(path)
      begin
        # We use URI#open because it can handle file or URI paths.
        # This usage does not expose a security risk
        contents = URI.open(path).read # rubocop:disable Security/Open
      rescue Errno::ENOENT, SocketError
        raise "*Error:* Ensure *#{path}* is a valid file path or URL"
      end

      begin
        modules = if path.end_with? '.json'
                    JSON.parse(contents)
                  else
                    YAML.safe_load(contents)
                  end
      rescue StandardError
        raise "*Error:* Ensure syntax of #{path} file is valid YAML or JSON"
      end

      # transform from IAC supported module hash to simple list
      modules = modules.filter_map { |_key, val| val['puppet_module'] } if modules.is_a? Hash

      modules
    end

    # Post message to terminal
    # @param message [String]
    def post(message)
      puts message
    end
  end
end
