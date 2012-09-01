
$:.unshift('.') # 1.9.2

require 'rubygems'
require 'rubygems/user_interaction' if Gem::RubyGemsVersion == '1.5.0'

require 'rake'
require 'rake/clean'
#require 'rake/rdoctask'


#
# clean

CLEAN.include('pkg', 'rdoc')


#
# test / spec

task :spec do

  sh 'rspec spec/'
end

task :test => [ :spec ]
task :default => [ :spec ]


#
# gem

GEMSPEC_FILE = Dir['*.gemspec'].first
GEMSPEC = eval(File.read(GEMSPEC_FILE))
GEMSPEC.validate


desc %{
  builds the gem and places it in pkg/
}
task :build do

  sh "gem build #{GEMSPEC_FILE}"
  sh "mkdir pkg" rescue nil
  sh "mv #{GEMSPEC.name}-#{GEMSPEC.version}.gem pkg/"
end

desc %{
  builds the gem and pushes it to rubygems.org
}
task :push => :build do

  sh "gem push pkg/#{GEMSPEC.name}-#{GEMSPEC.version}.gem"
end


#
# rabbitmq preparation

desc %{
  prepare RabbitMQ (vhost, user, perms)
}
task :prepare do

  sh "rabbitmqctl add_vhost ruote-test"
  sh "rabbitmqctl add_user ruote ruote"
  sh "rabbitmqctl set_permissions -p ruote-test ruote '.*' '.*' '.*'"
end


##
## rdoc
##
## make sure to have rdoc 2.5.x to run that
#
#Rake::RDocTask.new do |rd|
#
#  rd.main = 'README.rdoc'
#  rd.rdoc_dir = 'rdoc'
#
#  rd.rdoc_files.include(
#    'README.rdoc', 'CHANGELOG.txt', 'CREDITS.txt', 'lib/**/*.rb')
#
#  rd.title = "#{GEMSPEC.name} #{GEMSPEC.version}"
#end
#
#
##
## upload_rdoc
#
#desc %{
#  upload the rdoc to rubyforge
#}
#task :upload_rdoc => [ :clean, :rdoc ] do
#
#  account = 'jmettraux@rubyforge.org'
#  webdir = '/var/www/gforge-projects/ruote'
#
#  sh "rsync -azv -e ssh rdoc/#{GEMSPEC.name}_rdoc #{account}:#{webdir}/"
#end
  #
  # leverarge rdoc.info instead

