require 'json'
require 'yaml'
require 'net/http'

module MetadataJsonDeps
  class Runner
    def initialize(filename, updated_module, updated_module_version, verbose, use_slack)
      @module_names = return_modules(filename)
      @updated_module = updated_module
      @updated_module_version = updated_module_version
      @verbose = verbose
      @forge = MetadataJsonDeps::ForgeHelper.new
      @use_slack = use_slack
      @slack_webhook = ENV['METADATA_JSON_DEPS_SLACK_WEBHOOK']
    end

    def run
      @updated_module = @updated_module.sub('-', '/')
      message = "Comparing modules against *#{@updated_module}* version *#{@updated_module_version}*\n\n"
      @module_names.each do |module_name|
        message += "Checking *#{module_name}*\n"
        metadata = @forge.get_metadata_json(module_name)
        checker = MetadataJsonDeps::MetadataChecker.new(metadata, @forge, @updated_module, @updated_module_version)
        dependencies = checker.dependencies

        if dependencies.empty?
          message += "\tNo dependencies listed\n\n"
          next
        end

        allMatch = true
        dependencies.each do |dependency, constraint, current, satisfied|
          if satisfied
            if @verbose
              message += "\t#{dependency} (#{constraint}) *matches* #{current}\n"
            end
          else
            allMatch = false
            message += "\t#{dependency} (#{constraint}) *doesn't match* #{current}\n"
          end
        end

        message += "\tAll dependencies match\n" if allMatch
        message += "\n"
      end

      puts message
      post_to_slack(message) if @use_slack
    rescue Interrupt
    end

    def return_modules(filename)
      raise "File '#{filename}' is empty/does not exist" if File.size?(filename).nil?
      YAML.safe_load(File.open(filename))
    end

    def post_to_slack(message)
      raise 'METADATA_JSON_DEPS_SLACK_WEBHOOK env var not specified' unless @slack_webhook

      uri = URI.parse(@slack_webhook)
      request = Net::HTTP::Post.new(uri)
      request.content_type = 'application/json'
      request.body = JSON.dump({
        'text' => message
      })

      req_options = {
        use_ssl: uri.scheme == 'https',
      }

      response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
        http.request(request)
      end

      raise 'Encountered issue posting to Slack' unless response.code == '200'
    end

    def self.run(filename, module_name, new_version, verbose = false, use_slack = false)
      self.new(filename, module_name, new_version, verbose, use_slack).run
    end
  end
end
