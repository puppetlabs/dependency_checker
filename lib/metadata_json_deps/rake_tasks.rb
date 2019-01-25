require 'metadata_json_deps'

desc 'Verify dependencies of a list of modules along with an override module version'
task :compare_dependencies, [:managed_modules, :module, :version, :verbose, :use_slack, :logs_file] do |_task, args|
  MetadataJsonDeps::Runner.run(args[:managed_modules], args[:module], args[:version], args[:verbose], args[:use_slack], args[:logs_file])
end
