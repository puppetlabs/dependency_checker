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
      begin
        @forge.get_mod(@updated_module.sub('/', '-'))
        SemanticPuppet::Version.parse(@updated_module_version)
      rescue StandardError => error
        message = "Error: Verify *#{@updated_module}* exists on Puppet Forge! Verify semantic versioning syntax *#{@updated_module_version}*. \n"
        puts message
        post_to_slack(message) if @use_slack
        post_to_logs(message) if @logs_file
        raise message
      end

      @updated_module = @updated_module.sub('/', '-')
      message = "Comparing modules against *#{@updated_module}* version *#{@updated_module_version}*\n\n"
      if check_deprecated(@forge.get_current_version(@updated_module), @forge.get_module_data(@updated_module))
        message += "The module you are comparing against #{@updated_module.upcase} is DEPRECATED.\n"
        puts message
        post_to_slack(message) if @use_slack
        post_to_logs(message) if @logs_file
        puts message
      end
      @updated_module = @updated_module.sub('-', '/')
      @module_names.each do |module_name|
        message += "Checking *#{module_name}*.\n"
        module_name = module_name.sub('/', '-')

        begin
          @forge.get_mod(module_name)
        rescue StandardError => error
          message += "Checked module name *#{module_name.sub('-', '/')}* could not be found. Verify *#{module_name.sub('-', '/')}* exists on Puppet Forge. \n\n"
          next
        end

        module_data = @forge.get_module_data(module_name)
        metadata = module_data['current_release']['metadata']
        checker = MetadataJsonDeps::MetadataChecker.new(metadata, @forge, @updated_module, @updated_module_version)
        dependencies = checker.dependencies

        message += "The checked module #{module_name.upcase} is DEPRECATED.\n" if check_deprecated(@forge.get_current_version(module_name), module_data)

        if dependencies.empty?
          message += "\tNo dependencies listed\n\n"
          next
        end

        allMatch = true
        not_deprecated = true
        dependencies.each do |dependency, constraint, current, satisfied|
          if satisfied
            if @verbose
              message += "\t#{dependency} (#{constraint}) *matches* #{current}\n"
            end
          else
            allMatch = false
            message += "\t#{dependency} (#{constraint}) *doesn't match* #{current}\n"
          end
          dependency = dependency.sub('/', '-')
          not_deprecated = false if check_deprecated(current, @forge.get_module_data(dependency))

          message += "\tThe dependency module #{dependency.upcase} is DEPRECATED.\n" if check_deprecated(current, @forge.get_module_data(dependency))
        end

        message += "\tAll dependencies match\n" if allMatch && not_deprecated
        message += "\n"
      end

      puts message
      post_to_slack(message) if @use_slack
      post_to_logs(message) if @logs_file
    rescue Interrupt
    end

    def check_deprecated(version, module_data)
      version.to_s.eql?('999.999.999') || version.to_s.eql?('99.99.99') || module_data['deprecated_at'] != nil
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
