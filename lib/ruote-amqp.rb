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

# AMQP participant and listener pair for ruote.
#
# == Documentation
#
# See #RuoteAMQP::Listener and #RuoteAMQP::Participant for detailed
# documentation on using each of them.
#
# == AMQP Notes
#
# RuoteAMQP uses durable queues and persistent messages by default, to ensure
# no messages get lost along the way and that running expressions doesn't have
# to be restarted in order for messages to be resent.
#
module RuoteAMQP
  VERSION = '0.9.21.1'

  autoload 'Participant', 'ruote-amqp/participant'
  autoload 'Listener',    'ruote-amqp/listener'

  class << self

    attr_writer :use_persistent_messages

    # Whether or not to use persistent messages (true by default)
    def use_persistent_messages?
      @use_persistent_messages = true if @use_persistent_messages.nil?
      @use_persistent_messages
    end
  end
end
