require 'rubygems'
require 'rake'

require 'lib/ruote-amqp'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = 'ruote-amqp'
    gemspec.version = RuoteAMQP::VERSION
    gemspec.summary = 'AMQP participant/listener pair for ruote 2.1'
    gemspec.email = 'kenneth.kalmer@gmail.com'
    gemspec.homepage = 'http://github.com/kennethkalmer/ruote-amqp'
    gemspec.authors = ['kenneth.kalmer@gmail.com']
    gemspec.extra_rdoc_files.include '*.txt'

    gemspec.add_dependency 'amqp', '>= 0.6.7'
    gemspec.add_dependency 'ruote', '>= 2.1.10'
      # ruote depends on rufus-json

    gemspec.add_development_dependency 'rspec'
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler not available. Install it with 'gem install jeweler'"
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :spec #=> :check_dependencies

task :default => :spec

begin
  require 'yard'
  YARD::Rake::YardocTask.new
rescue LoadError
  task :yardoc do
    abort "YARD is not available. In order to run yardoc, you must: sudo gem install yard"
  end
end
