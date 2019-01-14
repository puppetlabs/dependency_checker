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

    def get_metadata_json(name)
      name = name.sub('/', '-')
      version = @cache[name]
      metadata = @cache["#{name}-metadata"]

      version = get_current_version(name) unless version

      unless metadata
        @cache["#{name}-metadata"] = metadata = get_metadata("#{name}-#{version}")
      end

      metadata
    end

    def get_metadata_json_uri(module_name)
      uri = URI.parse(ENV['METADATA_JSON_URI_BASE'] + module_name)
      request = Net::HTTP::Get.new(uri.to_s)
      request.content_type = 'application/json'
      req_options = {
          use_ssl: uri.scheme == 'https',
      }

      response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
        http.request(request)
      end

      response.body
    end

    def check_deprecated_at(module_name)
      module_name = module_name.sub('/', '-')
      meta_complete = get_metadata_json_uri(module_name)
      details = JSON.parse(meta_complete)
      if details.has_key? 'deprecated_at'
        details['deprecated_at'] != nil
      end
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
