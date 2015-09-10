require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rake/extensiontask"

RSpec::Core::RakeTask.new(:spec)

gemspec = Gem::Specification.load('ruco.gemspec')
Rake::ExtensionTask.new do |ext|
  ext.name = 'cocor'
  ext.ext_dir = 'ext/cocor'
  ext.lib_dir = 'lib/cocor'
  ext.gem_spec = gemspec
  ext.source_pattern = "*.{c,cpp}" 
end

task :default => [:test]
task :test => [:compile, :spec]
