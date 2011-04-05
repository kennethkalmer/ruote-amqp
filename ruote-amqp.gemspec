# encoding: utf-8

Gem::Specification.new do |s|

  s.name = 'ruote-amqp'
  s.version = File.read('lib/ruote-amqp/version.rb').match(/VERSION = '([^']+)'/)[1]
  s.platform = Gem::Platform::RUBY
  s.authors = [ 'Kenneth Kalmer', 'John Mettraux' ]
  s.email = [ 'kenneth.kalmer@gmail.com', 'jmettraux@gmail.com' ]
  s.homepage = 'http://ruote.rubyforge.org'
  s.rubyforge_project = 'ruote'
  s.summary = 'AMQP participant/listener pair for ruote 2.1'
  s.description = %{
AMQP participant/listener pair for ruote 2.1
  }

  #s.files = `git ls-files`.split("\n")
  s.files = Dir[
    'Rakefile',
    'lib/**/*.rb', 'spec/**/*.rb', 'test/**/*.rb',
    '*.gemspec', '*.txt', '*.rdoc', '*.md'
  ]

  s.add_runtime_dependency 'amqp', '~> 0.7.0'
  s.add_runtime_dependency 'ruote', ">= #{s.version}"

  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec', ">= 2.2.1"

  s.require_path = 'lib'
end

