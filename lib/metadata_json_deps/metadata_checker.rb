require 'semantic_puppet'

module MetadataJsonDeps
  class MetadataChecker
    def initialize(metadata, forge, updated_module, updated_module_version)
      @metadata = metadata
      @forge = forge
      @updated_module = updated_module
      @updated_module_version = updated_module_version
    end

    def module_dependencies
      return [] unless @metadata['dependencies']

      @metadata['dependencies'].map do |dep|
        constraint = dep['version_requirement'] || '>= 0'
        [dep['name'], SemanticPuppet::VersionRange.parse(constraint)]
      end
    end

    def dependencies
      module_dependencies.map do |dependency, constraint|
        dependency = dependency.sub('-', '/')
        current = dependency == @updated_module ? SemanticPuppet::Version.parse(@updated_module_version) : @forge.get_current_version(dependency)
        [dependency, constraint, current, constraint.include?(current)]
      end
    end
  end
end
