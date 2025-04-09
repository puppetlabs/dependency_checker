# frozen_string_literal: true

require 'dependency_checker'

describe 'compare_dependencies' do
  managed_modules_file = File.join(File.expand_path(File.dirname(__FILE__, 2)),
                                   'fixtures/managed_modules.yaml')
  managed_modules_url = 'https://raw.githubusercontent.com/puppetlabs/dependency_checker/main/spec/fixtures/managed_modules.yaml'
  # module_name = 'puppetlabs-stdlib'
  # version = '10.0.0'
  verbose = false

  context 'run executable with namespace' do
    it 'is expected to run without errors' do
      expect do
        runner = DependencyChecker::Runner.new(verbose)
        runner.resolve_from_namespace('puppetlabs', 'supported')
        runner.run
      end.not_to raise_error
    end
  end

  context 'run executable with list of modules' do
    it 'when passed a file of modules' do
      expect do
        runner = DependencyChecker::Runner.new(verbose)
        runner.resolve_from_path(managed_modules_file)
        runner.run
      end.not_to raise_error
    end

    it 'when passed a url with modules' do
      expect do
        runner = DependencyChecker::Runner.new(verbose)
        runner.resolve_from_path(managed_modules_url)
        runner.run
      end.not_to raise_error
    end
  end

  context 'run executable with invalid arguments' do
    it 'is expected to raise an error when managed_modules is not found' do
      error_message = '*Error:* Ensure *invalid_path* is a valid file path or URL'
      expect do
        runner = DependencyChecker::Runner.new(verbose)
        runner.resolve_from_path('invalid_path')
        runner.run
      end.to raise_error(RuntimeError, error_message)
    end

    it 'is expected to raise an error when module name could not be found in the Forge' do
      error_message = '*Error:* Could not find *invalid_name* on Puppet Forge! Ensure updated_module argument is valid.'
      expect do
        runner = DependencyChecker::Runner.new(verbose)
        runner.resolve_from_path(managed_modules_file)
        runner.override = ['invalid_name', '1.0.0']
        runner.run
      end.to raise_error(RuntimeError, error_message)
    end

    it 'is expected to raise an error when version has an invalid syntax' do
      error_message = '*Error:* Verify semantic versioning syntax *1.00* of updated_module_version argument.'
      expect do
        runner = DependencyChecker::Runner.new(verbose)
        runner.resolve_from_path(managed_modules_file)
        runner.override = ['puppetlabs-stdlib', '1.00']
        runner.run
      end.to raise_error(RuntimeError, error_message)
    end
  end
end
