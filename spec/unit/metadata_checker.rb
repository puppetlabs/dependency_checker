require 'metadata_json_deps'

describe 'metadata_checker' do

  before(:all) do
    @forge = MetadataJsonDeps::ForgeHelper.new
    @updated_module = 'puppetlabs-stdlib'
    @updated_module_version = '10.0.0'
    @metadata = @forge.get_mod(@updated_module)
    metadata = @forge.get_module_data('puppetlabs-motd')["current_release"]["metadata"]
    @checker = MetadataJsonDeps::MetadataChecker.new(metadata, @forge, @updated_module, @updated_module_version)
  end

  context 'check_dependencies method' do
    it 'returns correct results' do
      expect(@checker.check_dependencies).to eq(
        [
          ["puppetlabs/registry", SemanticPuppet::VersionRange.parse('>=1.0.0 <3.0.0'),  SemanticPuppet::Version.parse('2.1.0'), true],
          ["puppetlabs/stdlib", SemanticPuppet::VersionRange.parse('>=2.1.0 <6.0.0'), SemanticPuppet::Version.parse('5.2.0'), true],
          ["puppetlabs/translate", SemanticPuppet::VersionRange.parse('>=1.0.0 <2.0.0'), SemanticPuppet::Version.parse('1.2.0'), true],
        ]
      )
    end
  end

  context 'module_dependencies method' do
    it 'returns correct dependencies' do
      expect(@checker.send(:get_module_dependencies)).to eq(
        [
            ["puppetlabs/registry", SemanticPuppet::VersionRange.parse('>=1.0.0 <3.0.0')],
            ["puppetlabs/stdlib", SemanticPuppet::VersionRange.parse('>=2.1.0 <6.0.0')],
            ["puppetlabs/translate", SemanticPuppet::VersionRange.parse('>=1.0.0 <2.0.0')],
        ]
      )
    end
  end
end