$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

begin
  require 'openwfe'
rescue LoadError
  require 'rubygems'
  gem 'ruote', '>= 0.9.20'
  require 'openwfe'
end
require 'openwfe/version'

if OpenWFE::OPENWFERU_VERSION < '0.9.20'
  raise "ruote-amqp requires at least ruote-0.9.20"
end

require 'yaml'
require 'json'
require 'mq'

module RuoteAMQP
  VERSION = '0.9.20'

  autoload 'Participant', 'ruote-amqp/participant'
  autoload 'Listener',    'ruote-amqp/listener'
end
