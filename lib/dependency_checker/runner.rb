require 'json'
require 'yaml'
require 'net/http'
require 'uri'
require 'logger'
require 'parallel'

# Main runner for DependencyChecker
class DependencyChecker::Runner
  def initialize(managed_modules_arg, override, verbose)
    @managed_modules_arg = managed_modules_arg
    @override = !override.nil?
    @updated_module = override[0] if @override
    @updated_module_version = override[1] if @override
    @verbose = verbose
    @forge = DependencyChecker::ForgeHelper.new
  end

  def run
    validate_override if @override

    message = "_*Starting dependency checks...*_\n\n"

    # If override is enabled
    message += "Overriding *#{@updated_module}* version with *#{@updated_module_version}*\n\n" if @override

    # Post warning if @updated_module is deprecated
    message += "The module you are comparing against *#{@updated_module}* is *deprecated*.\n\n" if @override && @forge.check_module_deprecated(@updated_module)

    # Post message if using default managed_modules
    if @managed_modules_arg.nil?
      message += "No local path(s) to metadata.json or file argument specified. Defaulting to Puppet supported modules.\n\n"
      @managed_modules_arg = 'https://gist.githubusercontent.com/eimlav/6df50eda0b1c57c1ab8c33b64c82c336/raw/managed_modules.yaml'
    end

    @use_local_files = @managed_modules_arg.instance_of?(Array) || @managed_modules_arg.end_with?('.json')

    @modules = @use_local_files ? Array(@managed_modules_arg) : return_modules(@managed_modules_arg)

    # Post results of dependency checks
    message += run_dependency_checks
    message += 'All modules have valid dependencies.' if run_dependency_checks.empty?

    post(message)
  end

  # Validate override from runner and return an error if any issues are encountered
  def validate_override
    raise "*Error:* Could not find *#{@updated_module}* on Puppet Forge! Ensure updated_module argument is valid." unless check_module_exists(@updated_module)
    raise "*Error:* Verify semantic versioning syntax *#{@updated_module_version}* of updated_module_version argument." unless SemanticPuppet::Version.valid?(@updated_module_version)
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

      dependencies = @use_local_files ? get_dependencies_from_metadata(module_path) : get_dependencies(module_name)

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
      (all_match && !@verbose) ? '' : mod_message
    end

    message = ''
    messages.each do |result|
      message += result
    end

    message
  end

  # Get dependencies of a supplied module and use the override values from @updated_module and @updated_module_version
  # to verify if the depedencies are satisfied
  # @param module_name [String]
  # @return [Map] a map of dependencies along with their constraint, current version and whether they satisfy the constraint
  def get_dependencies(module_name)
    module_data = @forge.get_module_data(module_name)

    metadata = module_data.current_release.metadata
    checker = DependencyChecker::MetadataChecker.new(metadata, @forge, @updated_module, @updated_module_version)
    checker.check_dependencies
  end

  # Get dependencies of a supplied module from a metadata.json file to verify if the depedencies are satisfied
  # @param module_name [String]
  # @return [Map] a map of dependencies along with their constraint, current version and whether they satisfy the constraint
  def get_dependencies_from_metadata(metadata_path)
    metadata = JSON.parse(File.read(metadata_path), symbolize_names: true)
    checker = DependencyChecker::MetadataChecker.new(metadata, @forge, @updated_module, @updated_module_version)
    checker.check_dependencies
  end

  # Get dependencies of a supplied module from a metadata.json file to verify if the depedencies are satisfied
  # @param module_name [String]
  # @return [Map] a map of dependencies along with their constraint, current version and whether they satisfy the constraint
  def get_name_from_metadata(metadata_path)
    metadata = JSON.parse(File.read(metadata_path), symbolize_names: true)
    metadata[:name]
  end

  # Retrieve the array of module names from the supplied filename/URL
  # @return [Array] an array of module names
  def return_modules(managed_modules_path)
    managed_modules = {}
    managed_modules_yaml = {}

    begin
      if managed_modules_path =~ URI::DEFAULT_PARSER.make_regexp
        managed_modules = Net::HTTP.get(URI.parse(managed_modules_path))
      elsif File.file?(managed_modules_path)
        managed_modules = File.read(managed_modules_path)
      else
        raise 'Error'
      end
    rescue StandardError
      raise "*Error:* Ensure *#{managed_modules_path}* is a valid file path or URL"
    end

    begin
      managed_modules_yaml = YAML.safe_load(managed_modules)
    rescue StandardError
      raise '*Error:* Ensure syntax of managed_modules file is a valid YAML array'
    end

    managed_modules_yaml
  end

  # Post message to terminal
  # @param message [String]
  def post(message)
    puts message
  end

  def self.run_with_args(managed_modules_path, override, verbose)
    new(managed_modules_path, override, verbose).run
  end

  def self.run(managed_modules_path)
    new(managed_modules_path, nil, false, nil).run
  end
end
