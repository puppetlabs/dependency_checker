# frozen_string_literal: true

require 'dependency_checker'

describe 'dependency_checker' do
  before(:all) do
    @forge = DependencyChecker::ForgeHelper.new
    @updated_module = 'puppetlabs-stdlib'
    @updated_module_version = '9.3.0'
    metadata = @forge.get_module_data('puppetlabs-motd').current_release.metadata
    @checker = DependencyChecker::MetadataChecker.new(metadata, @forge, @updated_module, @updated_module_version)
  end

  context 'check_dependencies method' do
    it 'returns correct results' do
      expect(@checker.check_dependencies).to eq(
        [
          ['puppetlabs/registry', SemanticPuppet::VersionRange.parse('>=1.0.0 <6.0.0'), SemanticPuppet::Version.parse('5.0.1'), true],
          ['puppetlabs/stdlib', SemanticPuppet::VersionRange.parse('>=2.1.0 <10.0.0'), SemanticPuppet::Version.parse('9.3.0'), true]
        ]
      )
    end
  end
end
