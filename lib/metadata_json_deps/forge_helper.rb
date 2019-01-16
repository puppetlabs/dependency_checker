require 'puppet_forge'
require 'semantic_puppet'

module MetadataJsonDeps
  class ForgeHelper
    def initialize(cache = {})
      @cache = cache
    end

    def get_current_version(name)
      name = name.sub('/', '-')
      version = @cache[name]

      unless version
        @cache[name] = version = get_version(get_mod(name))
      end

      version
    end

    def get_module_data(module_name)
      uri = URI.parse('https://forgeapi.puppetlabs.com/v3/modules/' + module_name)
      request = Net::HTTP::Get.new(uri.to_s)
      request.content_type = 'application/json'
      req_options = {
          use_ssl: uri.scheme == 'https',
      }

      response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
        http.request(request)
      end

      JSON.parse(response.body)
    end

    private

    def get_mod(name)
      PuppetForge::Module.find(name)
    end

    def get_version(mod)
      SemanticPuppet::Version.parse(mod.current_release.version)
    end

    def get_metadata(name)
      PuppetForge::Release.find(name).metadata
    end
  end
end
