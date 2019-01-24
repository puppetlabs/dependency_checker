require 'puppet_forge'
require 'semantic_puppet'
require 'net/http'

module MetadataJsonDeps
  class ForgeHelper
    def initialize(cache = {})
      @cache = cache
    end

    # Retrieve current version of module
    # @return [SemanticPuppet::Version]
    def get_current_version(module_name)
      module_name = module_name.sub('/', '-')
      version = nil

      if @cache.key?(module_name)
        version = SemanticPuppet::Version.parse(@cache[module_name]["current_release"]["version"])
      end

      unless version
        version = get_version(get_module_data(module_name)) if (check_module_exists(module_name))
      end

      version
    end

    # Retrieve module data from Forge
    # @return [Hash] Hash containing JSON response from Forge
    def get_module_data(module_name)
      module_name = module_name.sub('/', '-')
      module_data = @cache[module_name]

      unless module_data
        @cache[module_name] = module_data = get_module_data_from_forge(module_name)
      end

      module_data
    end


    # Retrieve module from Forge
    # @return [PuppetForge::Module]
    def check_module_exists(module_name)
      return get_module_data(module_name) != nil
    end

    # Check if a module is deprecated from data fetched from the Forge
    # @return [Boolean] boolean result stating whether module is deprecated
    def check_module_deprecated(module_name)
      module_name = module_name.sub('/', '-')
      module_data = get_module_data(module_name)
      module_data['version'].to_s.eql?('999.999.999') || module_data['version'].to_s.eql?('99.99.99') || module_data['deprecated_at'] != nil
    end

    private

    def get_version(module_data)
      SemanticPuppet::Version.parse(module_data["current_release"]["version"])
    end

    def get_module_data_from_forge(module_name)
      uri = URI.parse('https://forgeapi.puppetlabs.com/v3/modules/' + module_name)
      request = Net::HTTP::Get.new(uri.to_s)
      request.content_type = 'application/json'
      req_options = {
          use_ssl: uri.scheme == 'https',
      }

      response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
        http.request(request)
      end
      
      return nil if response.code != "200"

      JSON.parse(response.body)
    end
  end
end
