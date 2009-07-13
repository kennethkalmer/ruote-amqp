begin
  require 'spec'
rescue LoadError
  require 'rubygems' unless ENV['NO_RUBYGEMS']
  gem 'rspec'
  require 'spec'
end

$:.unshift(File.dirname(__FILE__) + '/../lib')
require 'ruote-amqp'
require 'spec/ruote'
require 'fileutils'

# AMQP magic worked here
AMQP.settings[:vhost] = '/ruote-test'
AMQP.settings[:user]  = 'ruote'
AMQP.settings[:pass]  = 'ruote'

Spec::Runner.configure do |config|

  config.include( RuoteSpecHelpers )

  config.before(:each) do
    @tracer = Tracer.new

    ac = {}

    class << ac
      alias :old_put :[]=
      def []= (k, v)
        raise("!!!!! #{k.class}\n#{k.inspect}") \
          if k.class != String and k.class != Symbol
        old_put(k, v)
      end
    end
      #
      # useful for tracking misuses of the application context

    ac['__tracer'] = @tracer
    ac[:ruby_eval_allowed] = true
    ac[:definition_in_launchitem_allowed] = true

    @engine = OpenWFE::Engine.new( ac )

    @terminated_processes = []
    @engine.get_expression_pool.add_observer(:terminate) do |c, fe, wi|
      @terminated_processes << fe.fei.wfid
      #p [ :terminated, @terminated_processes ]
    end

    if ENV['DEBUG']
      $OWFE_LOG = Logger.new( STDOUT )
      $OWFE_LOG.level = Logger::DEBUG
    end
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
