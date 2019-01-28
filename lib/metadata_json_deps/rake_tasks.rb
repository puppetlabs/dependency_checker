require 'metadata_json_deps'

desc 'Verify dependencies of a list of modules along with an override module version'
task :compare_dependencies, [:managed_modules, :module, :version, :verbose, :use_slack, :logs_file] do |_task, args|
  MetadataJsonDeps::Runner.run(args[:managed_modules], args[:module], args[:version], args[:verbose], args[:use_slack], args[:logs_file])
end

desc 'Compare local module against dependencies of other modules'
task :compare_dependencies_current, [:managed_modules, :verbose, :use_slack, :logs_file] do |_task, args|
  metadata_file = File.read('metadata.json')
  metadata_json = JSON.parse(metadata_file)
  if metadata_json.is_a?(Hash) && !metadata_json.empty?
    module_name = metadata_json['name'].sub('-', '/')
    version = metadata_json['version']
    MetadataJsonDeps::Runner.run(args[:managed_modules], module_name, version, args[:verbose], args[:use_slack], args[:logs_file])
  end
end
