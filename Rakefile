### GENERATED FILE ###
# This file was generated with the script
# create_stub_klick_genome_rakefile.rb

namespace :rakefile do
  desc "Validate Rakefile dependencies and actions."
  task :validate do puts "  called validate" end
end
namespace :packages do
  task :clean do puts "  called clean" end
  task :nuget_restore do puts "  called nuget_restore" end
  task :copy_packages_to_dependencies => [:nuget_restore] do puts "  called copy_packages_to_dependencies" end
  task :remove_old_Web_bin_dlls do puts "  called remove_old_Web_bin_dlls" end
  desc "Copy dependencies to Web/bin"
  task :copy_to_web_bin => [:copy_packages_to_dependencies] do puts "  called copy_to_web_bin" end
  desc "Restore NuGet packages and load Web/bin/dependencies."
  task :restore => [:copy_to_web_bin, :remove_old_Web_bin_dlls] do puts "  called restore" end
  desc "List package references that should be fixed."
  task :list_web_bin_dependencies_refs do puts "  called list_web_bin_dependencies_refs" end
end
desc "Build any local files outside of Model or Web"
task :setuplocal do puts "  called setuplocal" end
desc "Compile cache"
task :compilecache do puts "  called compilecache" end
desc "Compile fingerprint"
task :compilefingerprint do puts "  called compilefingerprint" end
desc "Schema migration: Reset the db (eg, 'rake resetdb[\"intranet_darcy\"]')"
task :resetdb, :dbname do |t, args| puts "  called resetdb," end
desc "Schema migration: Run each script twice to check idempotency."
task :migrateschema do puts "  called migrateschema" end
desc "Schema migration: run each without checking idempotency or transactions"
task :migrateschemascary do puts "  called migrateschemascary" end
task :ms => [:migrateschema] do puts "  called ms" end
desc "Schema migration: run in a transaction"
task :migrateschemastage do puts "  called migrateschemastage" end
desc "Schema migration: run checking idempotency, with debug"
task :migrateschemadebug do puts "  called migrateschemadebug" end
desc "Schema migration: Run in transaction, with debug"
task :migrateschemastagedebug do puts "  called migrateschemastagedebug" end
task :migrateschemacreatetable do puts "  called migrateschemacreatetable" end
desc "Schema migration: check migrations have been run"
task :migrateschemacheck do puts "  called migrateschemacheck" end
desc "Schema migration: clean folders"
task :cleanschema do puts "  called cleanschema" end
desc "Schema migration: order folders"
task :orderschema do puts "  called orderschema" end
desc "Schema migration: lock folders"
task :lockschema do puts "  called lockschema" end
task :getmydb do puts "  called getmydb" end
desc "Schema migration: reset the db indicated in the Web.config"
task :resetmydb do puts "  called resetmydb" end
desc "Compile netsuitereplication"
task :compilenetsuitereplication do puts "  called compilenetsuitereplication" end
desc "Generate the model"
task :genmodel do puts "  called genmodel" end
desc "Compile model"
task :compilemodel do puts "  called compilemodel" end
desc "Compile Services"
task :compileservices do puts "  called compileservices" end
desc "Compile SignalR"
task :compilesignalr do puts "  called compilesignalr" end
desc "Compile Utility"
task :compileutility do puts "  called compileutility" end
task :compilelocalearly do puts "  called compilelocalearly" end
desc "Compile crons"
task :compilecron do puts "  called compilecron" end
desc "Compile MythRunner"
task :compilemythrunner do puts "  called compilemythrunner" end
desc "Compile CMS"
task :compilecms do puts "  called compilecms" end
task :checkmsbuildversion do puts "  called checkmsbuildversion" end
task :compileqaattributedecorator => :checkmsbuildversion do puts "  called compileqaattributedecorator" end
task :compileqauitesting => :checkmsbuildversion do puts "  called compileqauitesting" end
task :recycle do puts "  called recycle" end
desc "Fixes the csproj files."
task :fixcsproj do puts "  called fixcsproj" end
desc "Fix the Web config"
task :fixwebconfig do puts "  called fixwebconfig" end
task :copyconfigs do puts "  called copyconfigs" end
namespace :jenkins do
  desc "Update Web/elements/embeddable/dashboard/config.xml."
  task :fix_configs do puts "  called fix_configs" end
  desc "Create Jenkins pipeline configuration file."
  task :config do puts "  called config" end
end
namespace :nlog do
  desc "Use specified config file ('e.g., rake nlog:use_config[NLog.config.CI]')"
  task :use_config, :configfile do |t, args| puts "  called use_config," end
  desc "Use default config"
  task :use_default do puts "  called use_default" end
  task :list do puts "  called list" end
  task :show do puts "  called show" end
  task :delete do puts "  called delete" end
end
desc "Compile C# code"
task :cs => ['packages:restore', :copyssdeps, :fixwebconfig, :compileutility, :compilecache, :compilefingerprint, :compiless, :genmodel, :fixcsproj, :compilemodel, :compilenetsuitereplication, :compilesignalr, :compileservices, :fixconfigforradeditor, :compileweb, :compilecron, :compilemythrunner, :compilecms, :unittests] do puts "  called cs" end
desc "Compiles and sets some base configs."
task :base => [:cs, :setuplocal, 'nlog:use_default', :copyconfigs] do puts "  called base" end
desc "Default: checks migrations (doesn't migrate), and builds."
task :default => [:migrateschemacheck, :base, :compileClient] do puts "  called default" end
task :defaultstage => [:migrateschemacheck, :base, :compileClientStage, :generateManifest] do puts "  called defaultstage" end
task :noschema => [:base, :compileClient] do puts "  called noschema" end
task :noschemastage => [:base, :compileClientStage, :recycle] do puts "  called noschemastage" end
desc "Compile unit tests (alias for compiletests)."
task :unittests => [:compiletests] do puts "  called unittests" end
desc "Compile unit tests."
task :compiletests do puts "  called compiletests" end
desc "Compile Web"
task :compileweb do puts "  called compileweb" end
desc "Copy SmartSite dependencies"
task :copyssdeps do puts "  called copyssdeps" end
desc "Compile SmartSite"
task :compiless do puts "  called compiless" end
desc "Runs the default options, and re-generates cache keys"
task :stage => [ :compileSlack ] do puts "  called stage" end
desc "Runs the default options, and re-generates cache keys"
task :cleanstage => [ :compileSlack ] do puts "  called cleanstage" end
task :pause do puts "  called pause" end
task :testslack => [ :compileSlack ] do puts "  called testslack" end
desc "Run unit tests (with optional filter, e.g., rake runtests[\"cat==TaskProtectedDeadline\"])"
task :runtests, :filter do |t, args| puts "  called runtests," end
desc "Runs tasks to take place before any client app build"
task :clientPreBuild do puts "  called clientPreBuild" end
desc "Changes the theme for a specific site"
task :changetheme, :sitename do |t, args| puts "  called changetheme," end
desc "Checks that the installed Node & npm versions are of a supported version for this build"
task :checkNodeVersion do puts "  called checkNodeVersion" end
desc "Updates & installs client app dependancies"
task :updateClientDependancies do puts "  called updateClientDependancies" end
desc "Development build of client app"
task :compileClient => [ :setuplocal ] do puts "  called compileClient" end
desc "Production / Stage build of client app"
task :compileClientStage do puts "  called compileClientStage" end
desc "Generate manifest.json"
task :generateManifest do puts "  called generateManifest" end
task :compileSlack do puts "  called compileSlack" end
desc "Remove files in bin and NotEditable"
task :clean do puts "  called clean" end
desc "Look for TODO and FIXME tags in the code"
task :todo do puts "  called todo" end
desc "Add RadEditor HTTP handlers to Web.config"
task :fixconfigforradeditor do puts "  called fixconfigforradeditor" end
