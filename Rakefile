
require 'rubygems'
require 'rake'

require 'lib/ruote-amqp/version'


#
# GEM

require 'jeweler'

Jeweler::Tasks.new do |gemspec|

  gemspec.name = 'ruote-amqp'
  gemspec.version = RuoteAMQP::VERSION
  gemspec.summary = 'AMQP participant/listener pair for ruote 2.1'

  gemspec.description = %{
    AMQP participant/listener pair for ruote 2.1'
  }

  gemspec.email = 'kenneth.kalmer@gmail.com'
  gemspec.homepage = 'http://github.com/kennethkalmer/ruote-amqp'
  gemspec.authors = [ 'kenneth.kalmer@gmail.com', 'jmettraux@gmail.com' ]
  gem.rubyforge_project = 'ruote'
  gemspec.extra_rdoc_files.include '*.txt'

  gemspec.add_dependency 'amqp', '>= 0.6.7'
  gemspec.add_dependency 'ruote', ">= #{RuoteAMQP::VERSION}"
    # ruote depends on rufus-json

  gemspec.add_development_dependency 'rspec', '>= 2.1.0'
end
Jeweler::GemcutterTasks.new


#
# TEST / SPEC

#task :spec => :check_dependencies do
task :spec do
  sh 'rspec spec/'
end

task :default => :spec


#
# CLEAN

require 'rake/clean'
CLEAN.include('pkg', 'tmp', 'html', 'rdoc')


#
# DOC

#
# make sure to have rdoc 2.5.x to run that
#
require 'rake/rdoctask'
Rake::RDocTask.new do |rd|
  rd.main = 'README.rdoc'
  rd.rdoc_dir = 'rdoc/ruote-amqp_rdoc'
  rd.rdoc_files.include(
    'README.rdoc', 'CHANGELOG.txt', 'lib/**/*.rb')
  rd.title = "ruote-amqp #{RuoteAMQP::VERSION}"
end


#
# TO THE WEB

task :upload_rdoc => [ :clean, :rdoc ] do

  account = 'jmettraux@rubyforge.org'
  webdir = '/var/www/gforge-projects/ruote'

  sh "rsync -azv -e ssh rdoc/ruote-amqp_rdoc #{account}:#{webdir}/"
end

