# frozen_string_literal: true

require 'puppet_forge'
require 'semantic_puppet'

# Helper class for fetching data from the Forge and perform some basic operations
class DependencyChecker::ForgeHelper
  def initialize(cache = {}, forge_hostname = nil, forge_token = nil)
    @cache = cache
    PuppetForge.host = forge_hostname unless forge_hostname.nil?
    PuppetForge::Connection.authorization = forge_token unless forge_token.nil?
  end

  # Retrieve current version of module
  # @return [SemanticPuppet::Version]
  def get_current_version(module_name)
    module_name = module_name.sub('/', '-')
    version = nil
    version = get_version(@cache[module_name]) if @cache.key?(module_name)

    if !version && check_module_exists(module_name)
      version = get_version(get_module_data(module_name))
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

  # Gets a list of all modules in a namespace, optionally filtered by endorsement.
  # @param [String] namespace The namespace to search
  # @param [String] endorsement to filter by (supported/approved/partner)
  # @return [Array] list of modules
  def modules_in_namespace(namespace, endorsement = nil)
    modules = PuppetForge::Module.where(
                :owner           => namespace, # rubocop:disable Layout/FirstArgumentIndentation
                :hide_deprecated => true,
                :module_groups   => 'base pe_only',
                :endorsements    => endorsement,
              )

    raise "No modules found for #{namespace}." if modules.total.zero?

    modules.unpaginated.map { |m| m.slug }
  end

  private

  def get_version(module_data)
    return SemanticPuppet::Version.parse('999.999.999') unless module_data.current_release

    SemanticPuppet::Version.parse(module_data.current_release.version)
  end
end
