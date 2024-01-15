# frozen_string_literal: true

if ENV['COVERAGE'] == 'yes'
  begin
    require 'simplecov'
    require 'simplecov-console'

    SimpleCov.formatters = [
      SimpleCov::Formatter::HTMLFormatter,
      SimpleCov::Formatter::Console
    ]

    if ENV['CI'] == 'true'
      require 'codecov'
      SimpleCov.formatters << SimpleCov::Formatter::Codecov
    end

    SimpleCov.start do
      track_files 'lib/**/*.rb'
      add_filter '/spec'
      add_filter 'lib/dependency_checker/version.rb'

      # do not track vendored files
      add_filter '/vendor'
      add_filter '/.vendor'
    end
  rescue LoadError
    raise 'Add the simplecov, simplecov-console, codecov gems to Gemfile to enable this task'
  end
end
