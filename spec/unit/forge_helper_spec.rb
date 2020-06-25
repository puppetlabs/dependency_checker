# frozen_string_literal: true

require 'dependency_checker'

describe 'forge_helper' do
  before(:all) do
    @forge_helper = DependencyChecker::ForgeHelper.new
  end

  context 'get_current_version method' do
    it 'with valid module name' do
      expect(@forge_helper.get_current_version('puppetlabs-strings')).to match SemanticPuppet::Version.parse('999.999.999')
    end

    it 'with invalid module name' do
      expect(@forge_helper.get_current_version('puppetlabs-waffle')).to eq(nil)
    end

    it 'with slash in module name' do
      expect(@forge_helper.get_current_version('puppetlabs/strings')).to match SemanticPuppet::Version.parse('999.999.999')
    end
  end

  context 'get_module_data method' do
    it 'with valid module name' do
      response = @forge_helper.get_module_data('puppetlabs-strings')
      expect(response).to_not eq(nil)
    end

    it 'with invalid module name' do
      response = @forge_helper.get_module_data('puppetlabs-waffle')
      expect(response).to eq(nil)
    end
  end

  context 'check_module_exists method' do
    it 'with valid module name' do
      expect(@forge_helper.check_module_exists('puppetlabs-strings')).to eq(true)
    end

    it 'with invalid module name' do
      expect(@forge_helper.check_module_exists('puppetlabs-waffle')).to eq(false)
    end
  end

  context 'get_version' do
    it 'with valid module name' do
      expect(@forge_helper.send(:get_version, @forge_helper.get_module_data('puppetlabs-strings'))).to match SemanticPuppet::Version.parse('999.999.999')
    end
  end
end
