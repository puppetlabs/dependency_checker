require 'semantic_puppet'

# Checks dependencies of passed in metadata and performs checks to verify constraints
class DependencyChecker::MetadataChecker
  def initialize(metadata, forge, updated_module, updated_module_version)
    @metadata = metadata
    @forge = forge
    @updated_module = updated_module.sub('-', '/') if updated_module
    @updated_module_version = updated_module_version if updated_module_version
  end

  # Perform constraint comparisons of dependencies based on their latest version, and also
  # override any occurance of @updated_module with @updated_module_version
  # @return [Map] a map of dependencies along with their constraint, current version and whether they satisfy the constraint
  def check_dependencies
    fetch_module_dependencies.map do |dependency, constraint|
      dependency = dependency.sub('-', '/')
      current = (dependency == @updated_module) ? SemanticPuppet::Version.parse(@updated_module_version) : @forge.get_current_version(dependency)
      [dependency, constraint, current, constraint.include?(current)]
    end
  end

  private

  # Retrieve dependencies from @metedata
  # @return [Map] a map with the name of the dependency and its constraint
  def fetch_module_dependencies
    return [] unless @metadata[:dependencies]

    @metadata[:dependencies].map do |dep|
      constraint = dep[:version_requirement] || '>= 0'
      [dep[:name], SemanticPuppet::VersionRange.parse(constraint)]
    end
  end
end
