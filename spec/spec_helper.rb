begin
  require 'spec'
rescue LoadError
  require 'rubygems' unless ENV['NO_RUBYGEMS']
  gem 'rspec'
  require 'spec'
end

$:.unshift(File.dirname(__FILE__) + '/../lib')
$:.unshift('../ruote/lib')

require 'fileutils'
require 'json'

require 'ruote/engine'
require 'ruote/log/test_logger'

require 'ruote-amqp'
require 'spec/ruote'


# AMQP magic worked here
AMQP.settings[:host]  = '172.16.133.50'
AMQP.settings[:vhost] = '/ruote-test'
AMQP.settings[:user]  = 'ruote'
AMQP.settings[:pass]  = 'ruote'

Spec::Runner.configure do |config|

  config.include( RuoteSpecHelpers )

  config.before(:each) do
    @tracer = Tracer.new

    ac = {}

    ac[:s_tracer] = @tracer
    ac[:ruby_eval_allowed] = true
    ac[:definition_in_launchitem_allowed] = true

    @engine = ::Ruote::Engine.new( ac )

    @engine.add_service( :s_logger, ::Ruote::TestLogger )
  end

  config.after(:each) do
    @engine.stop
    AMQP.stop { EM.stop }
    sleep 0.001 while EM.reactor_running?
  end

  config.after(:all) do
    base = File.expand_path( File.dirname(__FILE__) + '/..' )
    FileUtils.rm_rf( base + '/logs' )
    FileUtils.rm_rf( base + '/work' )
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
