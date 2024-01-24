# frozen_string_literal: true

if ENV['COVERAGE'] == 'yes'
  begin
    require 'simplecov'
    require 'simplecov-console'

    SimpleCov.formatters = [
      SimpleCov::Formatter::HTMLFormatter,
      SimpleCov::Formatter::Console
    ]

    SimpleCov.start do
      track_files 'lib/**/*.rb'
      add_filter '/spec'
      add_filter 'lib/dependency_checker/version.rb'

      # do not track vendored files
      add_filter '/vendor'
      add_filter '/.vendor'
    end
  rescue LoadError
    raise 'Add the simplecov & simplecov-console gems to Gemfile to enable this task'
  end
end
