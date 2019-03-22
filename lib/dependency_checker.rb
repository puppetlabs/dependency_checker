# Module for checking the dependencies of Puppet Module using data retrieved from the Puppet Forge.
module DependencyChecker
  autoload :ForgeHelper, 'dependency_checker/forge_helper'
  autoload :MetadataChecker, 'dependency_checker/metadata_checker'
  autoload :Runner, 'dependency_checker/runner'
end
