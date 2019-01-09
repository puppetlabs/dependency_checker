require 'metadata_json_deps'

desc 'Compare specfified module and version against dependencies of other modules'
task :compare_dependencies, [:managed_modules, :module, :version, :verbose, :use_slack] do |task, args|
  MetadataJsonDeps::Runner.run(args[:managed_modules], args[:module], args[:version], args[:verbose], args[:use_slack])
end