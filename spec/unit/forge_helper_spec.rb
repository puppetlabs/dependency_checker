require 'metadata_json_deps'

describe 'forge_helper' do

  before(:all) do
    @forge_helper = MetadataJsonDeps::ForgeHelper.new
  end

  context 'get_current_version method' do
    it 'with valid module name' do
      expect(@forge_helper.get_current_version('puppetlabs-strings')).to match SemanticPuppet::Version.parse('999.999.999')
    end

    it 'with invalid module name' do
      expect{ @forge_helper.get_current_version('puppetlabs-waffle') }.to raise_error(Faraday::ResourceNotFound)
    end

    it 'with slash in module name' do
      expect(@forge_helper.get_current_version('puppetlabs/strings')).to match SemanticPuppet::Version.parse('999.999.999')
    end
  end

  context 'get_module_data method' do
    it 'with valid module name' do
      response = @forge_helper.get_module_data('puppetlabs-strings')
      expect(response["errors"]).to eq(nil)
    end

    it 'with invalid module name' do
      response = @forge_helper.get_module_data('puppetlabs-waffle')
      expect(response["errors"]).to_not eq(nil)
    end
  end

  context 'get_mod method' do
    it 'with valid module name' do
      expect(@forge_helper.get_mod('puppetlabs-strings').name).to match %r{strings}
    end

    it 'with invalid module name' do
      expect{ @forge_helper.get_mod('puppetlabs-waffle') }.to raise_error(Faraday::ResourceNotFound)
    end
  end

  context 'get_version' do
    it 'with valid module name' do
      expect(@forge_helper.send(:get_version, @forge_helper.get_mod('puppetlabs-strings'))).to match SemanticPuppet::Version.parse('999.999.999')
    end
  end
end