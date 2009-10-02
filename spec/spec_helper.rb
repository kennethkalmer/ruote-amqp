require 'rubygems'
gem 'rspec'
require 'spec'

$:.unshift(File.dirname(__FILE__) + '/../lib')
$:.unshift('../ruote/lib')

# For the tests to work you need to use the AMQP gem built from
# http://github.com/kennethkalmer/amqp.git
gem 'amqp', '=0.6.4'

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

#AMQP.logging = true

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
