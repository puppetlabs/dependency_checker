require 'puppet_forge'
require 'semantic_puppet'

# Helper class for fetching data from the Forge and perform some basic operations
class DependencyChecker::ForgeHelper
  def initialize(cache = {})
    @cache = cache
  end

  # Retrieve current version of module
  # @return [SemanticPuppet::Version]
  def get_current_version(module_name)
    module_name = module_name.sub('/', '-')
    version = nil
    version = get_version(@cache[module_name]) if @cache.key?(module_name)

    unless version
      version = get_version(get_module_data(module_name)) if check_module_exists(module_name)
    end

    version
  end

  # Retrieve module data from Forge
  # @return [Hash] Hash containing JSON response from Forge
  def get_module_data(module_name)
    module_name = module_name.sub('/', '-')
    module_data = @cache[module_name]
    begin
      @cache[module_name] = module_data = PuppetForge::Module.find(module_name) unless module_data
    rescue Faraday::ClientError
      return nil
    end

    module_data
  end

  # Retrieve module from Forge
  # @return [PuppetForge::Module]
  def check_module_exists(module_name)
    !get_module_data(module_name).nil?
  end

  # Check if a module is deprecated from data fetched from the Forge
  # @return [Boolean] boolean result stating whether module is deprecated
  def check_module_deprecated(module_name)
    module_name = module_name.sub('/', '-')
    module_data = get_module_data(module_name)
    version = get_current_version(module_name)
    version.to_s.eql?('999.999.999') || version.to_s.eql?('99.99.99') || !module_data.attribute('deprecated_at').nil?
  end

  private

  def get_version(module_data)
    SemanticPuppet::Version.parse(module_data.current_release.version)
  end
end
