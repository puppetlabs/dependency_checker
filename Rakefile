require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

namespace :spec do
  desc 'Run RSpec code examples with coverage collection'
  task :coverage do
    ENV['COVERAGE'] = 'yes'
    Rake::Task['spec'].execute
  end
end

RSpec::Core::RakeTask.new(:spec) do |t|
  t.exclude_pattern = 'spec/acceptance/**/*_spec.rb'
end
