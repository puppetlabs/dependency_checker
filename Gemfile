source 'https://rubygems.org'

forge_token = ENV.fetch('PUPPET_FORGE_TOKEN', nil)
gemsource_puppetcore = forge_token ? "https://#{forge_token}@rubygems-puppetcore.puppet.com" : 'https://rubygems.org'

gemspec

group :development do
  gem 'pry'
  gem 'pry-stack_explorer'
  gem 'fuubar'
end

group :test do
  gem 'benchmark'
  gem 'simplecov', require: false
  gem 'simplecov-console', require: false
  gem 'rspec', '~> 3.0', require: false
  gem 'rubocop', '~> 1.64.0', require: false
  gem 'rubocop-performance', '~> 1.16', require: false
  gem 'rubocop-rspec', '~> 3.0', require: false
end
