require 'json'
require 'yaml'
require 'net/http'
require 'logger'

module MetadataJsonDeps
  class Runner
    def initialize(filename, updated_module, updated_module_version, verbose, use_slack, logs_file)
      @module_names = return_modules(filename)
      @updated_module = updated_module
      @logs_file = logs_file
      @updated_module_version = updated_module_version
      @verbose = verbose
      @forge = MetadataJsonDeps::ForgeHelper.new
      @use_slack = use_slack
      @slack_webhook = ENV['METADATA_JSON_DEPS_SLACK_WEBHOOK']
    end

    def run
      @updated_module = @updated_module.sub('-', '/')
      message = "Comparing modules against *#{@updated_module}* version *#{@updated_module_version}*\n\n"
      if check_deprecated(@forge.get_current_version(@updated_module)) || @forge.check_deprecated_at(@updated_module)
        message += "The module you are comparing against #{@updated_module.upcase} is DEPRECATED.\n" #if check_deprecated(@forge.get_current_version(@updated_module)) || @forge.check_deprecated_at(@updated_module)
        puts message
        post_to_slack(message) if @use_slack
        post_to_logs(message) if @logs_file
        exit
      end
      @module_names.each do |module_name|
        message += "Checking *#{module_name}*\n"
        metadata = @forge.get_metadata_json(module_name)
        post_to_logs("\n\n") if @logs_file
        post_to_logs(metadata) if @logs_file
        checker = MetadataJsonDeps::MetadataChecker.new(metadata, @forge, @updated_module, @updated_module_version)
        dependencies = checker.dependencies

        message += "The checked module #{module_name.upcase} is DEPRECATED.\n" if check_deprecated(@forge.get_current_version(module_name)) || @forge.check_deprecated_at(module_name)

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
          message += "\tThe dependency module #{dependency.upcase} is DEPRECATED.\n" if check_deprecated(current) || @forge.check_deprecated_at(module_name)
        end

        message += "\tAll dependencies match\n" if allMatch
        message += "\n"
      end

      puts message
      post_to_slack(message) if @use_slack
      post_to_logs(message) if @logs_file
    rescue Interrupt
    end

    def check_deprecated(version)
      version.to_s.eql?('999.999.999') || version.to_s.eql?('99.99.99')
    end

    def return_modules(filename)
      raise "File '#{filename}' is empty/does not exist" if File.size?(filename).nil?
      YAML.safe_load(File.open(filename))
    end

    def post_to_logs(message)
      File.delete(@logs_file) if File.exists?(@logs_file)
      logger = Logger.new File.new(@logs_file, 'w')
      logger.datetime_format = "%Y-%m-%d %H:%M:%S"
      logger.info message
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

    def self.run(filename, module_name, new_version, verbose = 'false', use_slack = 'false', logs_file)
      
      
      self.new(filename, module_name, new_version, verbose == 'true', use_slack == 'true', logs_file).run
    end
  end
end
