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
