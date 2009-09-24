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

  VERSION = '2.0'

  autoload 'Participant', 'ruote-amqp/participant'
  autoload 'Listener',    'ruote-amqp/listener'

  class << self

    attr_writer :use_persistent_messages

    # Whether or not to use persistent messages (true by default)
    def use_persistent_messages?
      @use_persistent_messages = true if @use_persistent_messages.nil?
      @use_persistent_messages
    end

    def ensure_reactor! #:nodoc:
      Thread.main[:ruote_amqp_reactor] = Thread.new { EM.run } unless EM.reactor_running?
    end

    def shutdown_reactor! #:nodoc:
      if reactor_thread = Thread.main[:ruote_amqp_reactor]
        AMQP.stop { EM.stop }
        sleep 0.001 while EM.reactor_running?
      else
        AMQP.stop
      end
    end
  end
end
