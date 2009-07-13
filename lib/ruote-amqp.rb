$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

begin
  require 'openwfe'
rescue LoadError
  require 'rubygems'
  gem 'ruote', '>= 0.9.21'
  require 'openwfe'
end
require 'openwfe/version'

if OpenWFE::OPENWFERU_VERSION < '0.9.21'
  raise "ruote-amqp requires at least ruote-0.9.21"
end

require 'yaml'
require 'mq'

module RuoteAMQP
  VERSION = '0.9.21'

  autoload 'Participant', 'ruote-amqp/participant'
  autoload 'Listener',    'ruote-amqp/listener'
end
