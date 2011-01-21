
require 'rubygems'
require 'rspec'

$:.unshift(File.join(File.dirname(__FILE__), '../lib'))
$:.unshift(File.join(File.dirname(__FILE__), '../../ruote/lib'))

gem 'amqp', '=0.6.7'

require 'fileutils'
require 'json'

require 'ruote/engine'
require 'ruote/worker'
require 'ruote/storage/hash_storage'
require 'ruote/log/test_logger'

require 'ruote-amqp'

Dir[File.join(File.dirname(__FILE__), 'support/**/*.rb')].each { |path|
  require(path)
}


# AMQP magic worked here
AMQP.settings[:host]  = 'localhost'
AMQP.settings[:vhost] = 'ruote-test'
AMQP.settings[:user]  = 'ruote'
AMQP.settings[:pass]  = 'ruote'

#AMQP.logging = true

RSpec.configure do |config|

  config.include(RuoteSpecHelpers)

  config.before(:each) do
    @tracer = Tracer.new

    @engine = Ruote::Engine.new(
      Ruote::Worker.new(
        Ruote::HashStorage.new(
          's_logger' => [ 'ruote/log/test_logger', 'Ruote::TestLogger' ])))

    @engine.add_service('tracer', @tracer)
  end

  config.after(:each) do
    @engine.shutdown
    @engine.context.storage.purge!
  end

  config.after(:all) do
    base = File.expand_path(File.dirname(__FILE__) + '/..')
    FileUtils.rm_rf(base + '/logs')
    FileUtils.rm_rf(base + '/work')
  end
end


class Tracer
  def initialize
    @trace = ''
  end
  def to_s
    @trace.to_s.strip
  end
  def << s
    @trace << s
  end
  def clear
    @trace = ''
  end
  def puts s
    @trace << "#{s}\n"
  end
end

